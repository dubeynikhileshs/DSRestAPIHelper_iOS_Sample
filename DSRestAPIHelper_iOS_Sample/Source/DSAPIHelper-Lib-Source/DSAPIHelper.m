//
//  DSAPIHelper.m
//  DocuSignRestAPIHelper
//
//  Created by nik on 04/08/13.
//  Copyright (c) 2013 CloudSpokes. All rights reserved.
//

#import "DSAPIHelper.h"


@implementation DSAPIRecipient

@end

static DSAPIHelper * sharedHelper = nil;


@interface DSAPIHelper () {
    NSString *accountId;
    NSString *baseUrl;
    NSDictionary *authenticationHeader;
}
@property(nonatomic,strong)NSOperationQueue* backgroundQueue;
@end

@implementation DSAPIHelper

// Fetches the baseUrl and AccountID for given userId, password and IntegratorKey and stores it in instance variable.
// This method is called only once.
- (void)fetchBaseURLAndAccountId {
    // Enter your info:
    NSString *email = self.userId;
    NSString *password = self.password;
    NSString *integratorKey = self.integratorKey;
    
    //Return if email Integratorkey or Password is blank.
    if(!email.length) {
        NSLog(@"%s Email cannot be blank",__FUNCTION__);
        return;
    }
    else if(!password.length) {
        NSLog(@"%s Password cannot be blank",__FUNCTION__);
        return;
    }
    else if(!integratorKey.length) {
        NSLog(@"%s IntegratorKey cannot be blank",__FUNCTION__);
        return;
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////
    // STEP 1 - Login (retrieves accountId and baseUrl)
    ///////////////////////////////////////////////////////////////////////////////////////
    NSString *loginURL = @"https://demo.docusign.net/restapi/v2/login_information";
    NSMutableURLRequest *loginRequest = [[NSMutableURLRequest alloc] init];
    [loginRequest setHTTPMethod:@"GET"];
    [loginRequest setURL:[NSURL URLWithString:loginURL]];
    // set JSON formatted X-DocuSign-Authentication header (XML format also accepted)
    authenticationHeader = @{ @"Username": email, @"Password" : password, @"IntegratorKey" : integratorKey };
    // jsonStringFromObject() function defined below...
    [loginRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
    // also set the Content-Type header (other accepted type is application/xml)
    [loginRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //*** make synchronous web request
    NSURLResponse* loginResponse;
    NSError* loginError = nil;
    NSData* loginData = [NSURLConnection sendSynchronousRequest:loginRequest returningResponse:&loginResponse error:&loginError];
    NSError *jsonError = nil;
    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:loginData options:kNilOptions error:&jsonError];
    NSArray *loginArray = responseDictionary[@"loginAccounts"];
    // parse the accountId and baseUrl from the response and use in the next request
    accountId = loginArray[0][@"accountId"];
    baseUrl = loginArray[0][@"baseUrl"];
    
    NSLog(@"%s baseURL %@ accountId %@ ",__func__,baseUrl,accountId);
    
    
}

#pragma mark - Custom methods
//Fetches the baseURL and accountID only once.
- (void)fetchBaseURLIfRequired {
    if(!accountId.length || !baseUrl.length) {
        [self fetchBaseURLAndAccountId];
    }
}

- (NSString *)jsonStringFromObject:(id)object {
    NSString *string = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:object options:0 error:nil] encoding:NSUTF8StringEncoding];
    return string;
}


#pragma mark - Constructor
+ (DSAPIHelper *)sharedHelper {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelper = [[DSAPIHelper alloc] init];
    });
    
    return sharedHelper;
}

- (id)init {
    if(sharedHelper)
        return sharedHelper;
    if(self = [super init]) {
        baseUrl = nil;
        accountId = nil;
        _backgroundQueue = [[NSOperationQueue alloc] init];
    }
    sharedHelper = self;
    return self;
}




#pragma mark - DocusSignAPIs
- (NSBlockOperation*)embeddedDocuSignConsoleWithCompletionBlock:(DSAPICompletionBlock)completionBlock {
     [self fetchBaseURLIfRequired];//fetch the baseURL and accountID if its not already fetched by another API.

     if(!accountId.length || !baseUrl.length)
     return nil;

     NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
         ///////////////////////////////////////////////////////////////////////////////////////
         // STEP 2 - Get the Embedded DocuSign Console View
         ///////////////////////////////////////////////////////////////////////////////////////
         // append "/views/console" URI to your baseUrl and use as endpoint for next request
         NSString *consoleURL = [NSString stringWithFormat:@"%@/views/console",baseUrl];
         NSMutableURLRequest *consoleURLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:consoleURL]];
         [consoleURLRequest setHTTPMethod:@"POST"];
         [consoleURLRequest setURL:[NSURL URLWithString:consoleURL]];
         // request body only needs your accountId
         NSDictionary *consoleURLRequestData = @{@"accountId": accountId};
         // convert request body into an NSData object
         NSData* data = [[self jsonStringFromObject:consoleURLRequestData] dataUsingEncoding:NSUTF8StringEncoding];
         // attach body to the request
         [consoleURLRequest setHTTPBody:data];
         // authentication and content-type headers
         [consoleURLRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
         [consoleURLRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
         // Request the console URL...
         [NSURLConnection sendAsynchronousRequest:consoleURLRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *consoleResponse, NSData *consoleData, NSError *consoleError) {
             if (consoleError)
             {
                 NSLog(@"Error sending request %@. Got Response %@ Error is: %@", consoleURLRequest, consoleResponse, consoleError);
                 return;
             }
             NSError *jsonError = nil;
             NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:consoleData options:kNilOptions error:&jsonError];
             NSString *embeddedURLToken = responseDictionary[@"url"];
             //--- display results
             NSLog(@"URL token created - please navigate to the following URL to open the DocuSign Console:\n\n%@\n\n", embeddedURLToken);
             //NSURL *url = [NSURL URLWithString:embeddedURLToken];
             //NSLog(@"********** url %@ ********",url);
             //[[UIApplication sharedApplication] openURL:url];
             
             if(completionBlock) {
                 completionBlock(responseDictionary,consoleError);
             }
             
         }];
     }];
    [self.backgroundQueue addOperation:operation];
    return operation;
    

}

- (NSBlockOperation*)requestSignatureFromTemplateWithID:(NSString*)templateID forRecipient:(DSAPIRecipient*)recipient withEmailSubject:(NSString*)subject emailBlurb:(NSString*)blurb completionBlock:(DSAPICompletionBlock)completionBlock {
    [self fetchBaseURLIfRequired];//fetch the baseURL and accountID if its not already fetched by another API.
    if(!accountId.length || !baseUrl.length)
        return nil;
    
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        ///////////////////////////////////////////////////////////////////////////////////////
        // STEP 2 - Request Signature via Template
        ///////////////////////////////////////////////////////////////////////////////////////
        // append "/envelopes" URI to your baseUrl and use as endpoint for signature request call
        NSString *envelopesURL = [NSMutableString stringWithFormat:@"%@/envelopes",baseUrl];
        NSMutableURLRequest *signatureRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:envelopesURL]];
        [signatureRequest setHTTPMethod:@"POST"];
        [signatureRequest setURL:[NSURL URLWithString:envelopesURL]];
        
        // RecipientInfo
        NSString *visitorName =  recipient.fullName;
        NSString *visitorEmail = recipient.email;
        NSString *visitorRoleName = recipient.roleName;
        
        //ID of the template stored on server.
        NSString *templateId = templateID;
        NSString* emailSubject = subject;
        NSString* emailBlurb = blurb;
        
        if(!accountId.length || !baseUrl.length)
            return ;
        
        if(!visitorName.length) {
            NSLog(@"%s recipient.fullName cannot be blank",__FUNCTION__);
            if(completionBlock) {
                completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"recipient.fullName cannot be blank"}]);
            }
            return ;
        }
        else if(!visitorEmail.length) {
            NSLog(@"%s recipient.email cannot be blank",__FUNCTION__);
            if(completionBlock) {
                completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"recipient.email cannot be blank"}]);
            }
            return ;
        }
        else if(!visitorRoleName.length) {
            NSLog(@"%s recipient.roleName cannot be blank",__FUNCTION__);
            if(completionBlock) {
                completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"recipient.roleName cannot be blank"}]);
            }
            return ;
            
        }  else if(!templateId.length) {
            NSLog(@"%s templateId cannot be blank",__FUNCTION__);
            if(completionBlock) {
                completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"templateId cannot be blank"}]);
            }
            return ;
        }

        
        NSDictionary *signatureRequestData = nil;
        @try {
            // construct a JSON formatted signature request body (multi-line for readability)
            signatureRequestData = @{@"accountId": accountId,
                                                   @"emailSubject" : emailSubject,
                                                   @"emailBlurb" : emailBlurb,
                                                   @"templateId" : templateId,
                                                   @"templateRoles" : [NSArray arrayWithObjects: @{@"email":visitorEmail, @"name": visitorName, @"roleName": visitorRoleName }, nil ],
                                                   @"status" : @"sent"
                                                   };

        }
        @catch (NSException *exception) {
            NSLog(@"exception  %@",exception.description);
        }
        // convert request body into an NSData object
        NSData* data = [[self jsonStringFromObject:signatureRequestData] dataUsingEncoding:NSUTF8StringEncoding];
        // attach body to the request
        [signatureRequest setHTTPBody:data];
        [signatureRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
        [signatureRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        //*** make the signature request!
        [NSURLConnection sendAsynchronousRequest:signatureRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *envelopeResponse, NSData *envelopeData, NSError *envelopeError) {
            NSError *jsonError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:envelopeData options:kNilOptions error:&jsonError];
            NSLog(@"Envelope Sent! Response is: %@\n", responseDictionary);
            if(completionBlock){
                completionBlock(responseDictionary,envelopeError);
            }
            
        }];
    }];
    [self.backgroundQueue addOperation:operation];
    return operation;
    
}

- (NSBlockOperation*)envelopeInfoForEnvelopeId:(NSString*)envelopeID completionBlock:(DSAPICompletionBlock)completionBlock {
    [self fetchBaseURLIfRequired];//fetch the baseURL and accountID if its not already fetched by another API.
    if(!accountId.length || !baseUrl.length)
        return nil;
    
    if(!envelopeID.length) {
        NSLog(@"%s envelopeID cannot be blank",__FUNCTION__);
        if(completionBlock) {
            completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"envelopeID cannot be blank"}]);
        }
        return nil;
    }
    
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        ///////////////////////////////////////////////////////////////////////////////////////
        // STEP 2 - Get Envelope Info
        ///////////////////////////////////////////////////////////////////////////////////////
        // append "/envelopes/{envelopeId}" URI to your baseUrl and use as endpoint for next request
        NSString *envelopesURL = [NSMutableString stringWithFormat:@"%@/envelopes/%@",baseUrl, envelopeID];
        NSMutableURLRequest *envelopeRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:envelopesURL]];
        [envelopeRequest setHTTPMethod:@"GET"];
        [envelopeRequest setURL:[NSURL URLWithString:envelopesURL]];
        [envelopeRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
        [envelopeRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        //*** make the request!
        [NSURLConnection sendAsynchronousRequest:envelopeRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *envelopeResponse, NSData *envelopeData, NSError *envelopeError) {
            NSError *jsonError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:envelopeData options:kNilOptions error:&jsonError];
            //NSLog(@"Envelope info received is: %@\n", responseDictionary);
            if(completionBlock){
                completionBlock(responseDictionary,envelopeError);
            }
        }];
    }];
    [self.backgroundQueue addOperation:operation];    
    return operation;
}

- (NSBlockOperation*)recipientInfoForEnvelopeId:(NSString*)envelopeId completionBlock:(DSAPICompletionBlock)completionBlock  {
    [self fetchBaseURLIfRequired];//fetch the baseURL and accountID if its not already fetched by another API.
    if(!accountId.length || !baseUrl.length)
        return nil;
    
    if(!envelopeId.length) {
        NSLog(@"%s envelopeID cannot be blank",__FUNCTION__);
        if(completionBlock) {
            completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"envelopeID cannot be blank"}]);
        }
        return nil;
    }
    
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        ///////////////////////////////////////////////////////////////////////////////////////
        // STEP 2 - Get Recipient Info
        ///////////////////////////////////////////////////////////////////////////////////////
        // append "/envelopes/{envelopeId}" URI to your baseUrl and use as endpoint for next request
        NSString *envelopesURL = [NSMutableString stringWithFormat:@"%@/envelopes/%@/recipients", baseUrl, envelopeId];
        NSMutableURLRequest *envelopeRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:envelopesURL]];
        [envelopeRequest setHTTPMethod:@"GET"];
        [envelopeRequest setURL:[NSURL URLWithString:envelopesURL]];
        [envelopeRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
        [envelopeRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        //*** make the request!
        [NSURLConnection sendAsynchronousRequest:envelopeRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *envelopeResponse, NSData *envelopeData, NSError *envelopeError) {
            NSError *jsonError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:envelopeData options:kNilOptions error:&jsonError];
            if(completionBlock) {
                completionBlock(responseDictionary,envelopeError);
            }
        }];
    }];
    [self.backgroundQueue addOperation:operation];   
    return operation;
}

- (NSBlockOperation*)requestSignatureOnDocument:(NSString*)documentName  toRecipient:(DSAPIRecipient*)recipient withEmailSubject:(NSString*)subject emailBlurb:(NSString*)blurb completionBlock:(DSAPICompletionBlock)completionBlock  {
        [self fetchBaseURLIfRequired];//fetch the baseURL and accountID if its not already fetched by another API.
    if(!accountId.length || !baseUrl.length)
        return nil;
    
    if(!documentName.length) {
        NSLog(@"%s documentName cannot be blank",__FUNCTION__);
        if(completionBlock) {
            completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"documentName cannot be blank"}]);
        }
        return nil;
    }
    if(!recipient.fullName.length) {
        NSLog(@"%s recipient.fullName cannot be blank",__FUNCTION__);
        if(completionBlock) {
            completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"recipient.fullName cannot be blank"}]);
        }
        return nil;
    }
    if(!recipient.email.length) {
        NSLog(@"%s recipient.email cannot be blank",__FUNCTION__);
        if(completionBlock) {
            completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"recipient.email cannot be blank"}]);
        }
        return nil;
    }
    
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        ///////////////////////////////////////////////////////////////////////////////////////
        // STEP 2 - Request Signature on Document
        ///////////////////////////////////////////////////////////////////////////////////////
        // append "/envelopes" URI to your baseUrl and use as endpoint for signature request call
        NSString *envelopesURL = [NSMutableString stringWithFormat:@"%@/envelopes",baseUrl];
        NSMutableURLRequest *signatureRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:envelopesURL]];
        [signatureRequest setHTTPMethod:@"POST"];
        [signatureRequest setURL:[NSURL URLWithString:envelopesURL]];
        // construct a JSON formatted signature request body (multi-line for readability)
        NSDictionary *signatureRequestData =
        @{@"accountId": accountId,
          @"emailSubject" : subject,
          @"emailBlurb" : blurb,
          @"documents" : [NSArray arrayWithObjects: @{@"documentId":@"1", @"name": documentName}, nil ],
          @"recipients" : @{ @"signers": [NSArray arrayWithObjects:
                                          @{@"email": recipient.email,
                                          @"name": recipient.fullName,
                                          @"recipientId": @"1",
                                          @"tabs": @{ @"signHereTabs": [NSArray arrayWithObjects:
                                                                        @{@"xPosition": @"100",
                                                                        @"yPosition": @"100",
                                                                        @"documentId": @"1",
                                                                        @"pageNumber": @"1"}, nil ]}}, nil ] },
          @"status" : @"sent"
          };
        // convert dictionary object to JSON formatted string
        NSString *sigRequestDataString = [self jsonStringFromObject:signatureRequestData];
        // read document bytes and place in the request
        NSString* filePath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle]bundlePath],documentName];
        NSData *filedata = [NSData dataWithContentsOfFile:filePath];
        
        // create the boundary separated request body...
        NSMutableData *body = [NSMutableData data];
        [body appendData:[[NSString stringWithFormat:
                           @"\r\n"
                           "\r\n"
                           "--AAA\r\n"
                           "Content-Type: application/json\r\n"
                           "Content-Disposition: form-data\r\n"
                           "\r\n"
                           "%@\r\n"
                           "--AAA\r\n"
                           "Content-Type: application/pdf\r\n"
                           "Content-Disposition: file; filename=\"%@\"; documentid=1; fileExtension=\"pdf\" \r\n"
                           "\r\n",
                           sigRequestDataString, documentName] dataUsingEncoding:NSUTF8StringEncoding]];
        // next append the document bytes
        [body appendData:filedata];
        // append closing boundary and CRLFs
        [body appendData:[[NSString stringWithFormat:
                           @"\r\n"
                           "--AAA--\r\n"
                           "\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        // add the body to the request
        [signatureRequest setHTTPBody:body];
        [signatureRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
        [signatureRequest setValue:@"multipart/form-data; boundary=AAA" forHTTPHeaderField:@"Content-Type"];
        //*** make the signature request!
        [NSURLConnection sendAsynchronousRequest:signatureRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *envelopeResponse, NSData *envelopeData, NSError *envelopeError) {
            NSError *jsonError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:envelopeData options:kNilOptions error:&jsonError];
            if(completionBlock) {
                completionBlock(responseDictionary,envelopeError);
            }
        }];
 
    }];
    [self.backgroundQueue addOperation:operation];
    return operation;
    
}


- (NSBlockOperation*)statusOfEnvelopesWithcompletionBlock:(DSAPICompletionBlock)completionBlock {
    [self fetchBaseURLIfRequired];//fetch the baseURL and accountID if its not already fetched by another API.
    if(!accountId.length || !baseUrl.length)
        return nil;
    
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        ///////////////////////////////////////////////////////////////////////////////////////
        // STEP 2 - Get Status of Envelopes (using a date and status filter)
        ///////////////////////////////////////////////////////////////////////////////////////
        // create a date url parameter
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *dateString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-60*60*24*7]]; // 7 days ago
        // append /envelopes URI to baseUrl, then append a date and status filter in following format:
        // /envelopes?from_date=yyyy-MM-dd&status=created,sent,delivered,signed,completed
        NSString *envelopesURL = [NSString stringWithFormat:@"%@/envelopes?from_date=%@&status=created,sent,delivered,signed,completed", baseUrl, dateString];
        NSMutableURLRequest *envelopesRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:envelopesURL]];
        [envelopesRequest setHTTPMethod:@"GET"];
        [envelopesRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [envelopesRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
        [NSURLConnection sendAsynchronousRequest:envelopesRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *envelopesResponse, NSData *envelopesData, NSError *envelopesError) {
            NSError *envelopesJSONError = nil;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:envelopesData options:kNilOptions error:&envelopesJSONError];
            if(completionBlock){
                completionBlock(jsonResponse,envelopesError);
            }
        }];
    }];
    [self.backgroundQueue addOperation:operation];
    return operation;
}


- (NSBlockOperation*)documentInfoAndDownloadDocumentsForEnvelopeId:(NSString*)envelopeId completionBlock:(DSAPICompletionBlock)completionBlock {
    [self fetchBaseURLIfRequired];//fetch the baseURL and accountID if its not already fetched by another API.
    if(!accountId.length || !baseUrl.length)
        return nil;
    
    if(!envelopeId.length) {
        NSLog(@"%s envelopeID cannot be blank",__FUNCTION__);
        if(completionBlock) {
            completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"envelopeID cannot be blank"}]);
        }
        return nil;
    }
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        ///////////////////////////////////////////////////////////////////////////////////////
        // STEP 2 - Get Document Info for specified envelope
        ///////////////////////////////////////////////////////////////////////////////////////
        // append /envelopes/{envelopeId}/documents URI to baseUrl and use as endpoint for next request
        NSString *documentsURL = [NSMutableString stringWithFormat:@"%@/envelopes/%@/documents", baseUrl, envelopeId];
        NSMutableURLRequest *documentsRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:documentsURL]];
        [documentsRequest setHTTPMethod:@"GET"];
        [documentsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [documentsRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
        [NSURLConnection sendAsynchronousRequest:documentsRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *documentsResponse, NSData *documentsData, NSError *documentsError) {
            if (documentsError){
                NSLog(@"Error sending request: %@. Got response: %@", documentsRequest, documentsResponse);
                NSLog( @"Response = %@", documentsResponse );
                if(completionBlock) {
                    completionBlock(nil,documentsError);
                }
                return;
            }
            //NSLog( @"Documents info for envelope is:\n%@", jsonResponse);
            NSError *jsonError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:documentsData options:kNilOptions error:&jsonError];
            // grab documents info for the next step...
            NSArray *documentsArray = responseDictionary[@"envelopeDocuments"];
            ///////////////////////////////////////////////////////////////////////////////////////
            // STEP 3 - Download each envelope document
            ///////////////////////////////////////////////////////////////////////////////////////
            
            
            NSMutableArray* docs = [NSMutableArray array];
            NSMutableArray* filePaths = [NSMutableArray array];
            
            
            NSMutableString *docUri;
            NSMutableString *docName;
            NSMutableString *docURL;
            // loop through each document uri and download each doc (including the envelope's certificate)
            for (int i = 0; i < [documentsArray count]; i++)
            {
                docUri = [documentsArray[i] objectForKey:@"uri"];
                docName = [documentsArray[i] objectForKey:@"name"];
                docURL = [NSMutableString stringWithFormat: @"%@/%@", baseUrl, docUri];
                [documentsRequest setHTTPMethod:@"GET"];
                [documentsRequest setURL:[NSURL URLWithString:docURL]];
                [documentsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                [documentsRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
                NSError *error = [[NSError alloc] init];
                NSHTTPURLResponse *responseCode = nil;
                NSData *oResponseData = [NSURLConnection sendSynchronousRequest:documentsRequest returningResponse:&responseCode error:&error];
                NSMutableString *jsonResponse = [[NSMutableString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
                if([responseCode statusCode] != 200){
                    NSLog(@"Error sending %@ request to %@\nHTTP status code = %i", [documentsRequest HTTPMethod], docURL, [responseCode statusCode]);
                    NSLog( @"Response = %@", jsonResponse );
                    return;
                }
                // download the document to the same directory as this app
                NSString *appDirectory = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
                NSMutableString *filePath = [NSMutableString stringWithFormat:@"%@/%@", appDirectory, docName];
                [oResponseData writeToFile:filePath atomically:YES];
                NSLog(@"Envelope document - %@ - has been downloaded to %@\n", docName, filePath);
                
                [filePaths addObject:[filePath copy]];
                [docs addObject:[docName copy]];
                
            } // end for
            
            NSString* message = @"";
            for (int i=0; i<docs.count; i++) {
                docName = docs[i];
                NSString*  filePath = filePaths[i];
               message = [message stringByAppendingString:[NSString stringWithFormat:@"%d) Envelope document - %@ - has been downloaded to %@\n\n",(i+1), docName, filePath]];
            }
            [self showMessage:message withDelegate:nil andButtonTitles:@[@"OK"]];
            
            if(completionBlock) {
                completionBlock(responseDictionary,documentsError);
            }
        }];
    }];
    [self.backgroundQueue addOperation:operation];
    return operation;
}

- (void)showMessage:(NSString*)message withDelegate:(id)delegate andButtonTitles:(NSArray*)buttonTitles{
    NSString* otherButtonTitle = nil;
    if(buttonTitles.count>1) {
        otherButtonTitle = buttonTitles[1];
    }
    UIAlertView* anAlert = [[UIAlertView alloc] initWithTitle:@"DSAPIHelper" message:message delegate:delegate cancelButtonTitle:buttonTitles[0] otherButtonTitles:otherButtonTitle, nil];
    [anAlert show];
}

- (NSBlockOperation*)embededSigningForTemplateWithID:(NSString*)templateID forRecipient:(DSAPIRecipient*)recipient withEmailSubject:(NSString*)subject emailBlurb:(NSString*)blurb completionBlock:(DSAPICompletionBlock)completionBlock {
    [self fetchBaseURLIfRequired];//fetch the baseURL and accountID if its not already fetched by another API.
    if(!accountId.length || !baseUrl.length)
        return nil;
    
    if(!templateID.length) {
        NSLog(@"%s templateID cannot be blank",__FUNCTION__);
        if(completionBlock) {
            completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"templateID cannot be blank"}]);
        }
        return nil;
    }
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        ///////////////////////////////////////////////////////////////////////////////////////
        // STEP 2 - Create Envelope via Template and send the envelope
        ///////////////////////////////////////////////////////////////////////////////////////
        // append "/envelopes" URI to your baseUrl and use as endpoint for signature request call
        NSString *envelopesURL = [NSString stringWithFormat:@"%@/envelopes",baseUrl];
        NSMutableURLRequest *signatureRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:envelopesURL]];
        [signatureRequest setHTTPMethod:@"POST"];
        [signatureRequest setURL:[NSURL URLWithString:envelopesURL]];
        // construct a JSON formatted signature request body (multi-line for readability)
        NSDictionary *signatureRequestData = @{@"accountId": accountId,
                                               @"emailSubject" : @"Embedded Sending API call",
                                               @"emailBlurb" : @"email body goes here",
                                               @"templateId" : templateID,
                                               @"templateRoles" : [NSArray arrayWithObjects: @{@"email":recipient.email, @"name": recipient.fullName, @"roleName": recipient.roleName, @"clientUserId": @"1001" }, nil ],
                                               @"status" : @"sent"
                                               };
        // convert request body into an NSData object
        NSData* data = [[self jsonStringFromObject:signatureRequestData] dataUsingEncoding:NSUTF8StringEncoding];
        // attach body to the request
        [signatureRequest setHTTPBody:data];
        // authentication and content-type headers
        [signatureRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
        [signatureRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        // Send the signature request...
        [NSURLConnection sendAsynchronousRequest:signatureRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *envelopeResponse, NSData *envelopeData, NSError *envelopeError) {
            NSError *jsonError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:envelopeData options:kNilOptions error:&jsonError];
            NSLog(@"Signature request sent, envelope info is: \n%@\n", responseDictionary);
            // parse envelopeId from resposne as it will be used in next request
            NSString *envelopeId = responseDictionary[@"envelopeId"];
            ///////////////////////////////////////////////////////////////////////////////////////
            // STEP 3 - Get the Embedded Signing View (aka recipient view) of the envelope
            ///////////////////////////////////////////////////////////////////////////////////////
            // append /envelopes/{envelopeId}/views/recipient to baseUrl and use in request
            NSString *embeddedURL = [NSString stringWithFormat:@"%@/envelopes/%@/views/recipient", baseUrl, envelopeId];
            NSMutableURLRequest *embeddedRequest = [[NSMutableURLRequest alloc] init];
            [embeddedRequest setHTTPMethod:@"POST"];
            [embeddedRequest setURL:[NSURL URLWithString:embeddedURL]];
            // simply set the returnUrl in the request body (user is directed here after signing)
            NSDictionary *embeddedRequestData = @{@"returnUrl": returnURI,
                                                  @"authenticationMethod" : @"none",
                                                  @"email" : recipient.email,
                                                  @"userName" : recipient.fullName,
                                                  @"clientUserId" : @"1001" // must match clientUserId set is step 2
                                                  };
            // convert request body into an NSData object
            NSData* data = [[self jsonStringFromObject:embeddedRequestData] dataUsingEncoding:NSUTF8StringEncoding];
            // attach body to the request
            [embeddedRequest setHTTPBody:data];
            // jsonStringFromObject() function defined below...
            [embeddedRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
            // also set the Content-Type header (other accepted type is application/xml)
            [embeddedRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            //*** make an asynchronous web request
            [NSURLConnection sendAsynchronousRequest:embeddedRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *embeddedResponse, NSData *embeddedData, NSError *embeddedError) {
                if (embeddedError) { // succesful POST returns status 201
                    NSLog(@"Error sending request %@. Got Response %@ Error is: %@", embeddedRequest, embeddedResponse, embeddedError);
                    return;
                }
                // we use NSJSONSerialization to parse the JSON formatted response
                NSError *jsonError = nil;
                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:embeddedData options:kNilOptions error:&jsonError];
                NSString *embeddedURLToken = responseDictionary[@"url"];
                if(completionBlock) {
                    completionBlock(responseDictionary,envelopeError);
                }
                //--- display results
                NSLog(@"URL token created - please navigate to the following URL to start the embedded signing workflow:\n\n%@\n\n", embeddedURLToken);
                NSURL *url = [NSURL URLWithString:embeddedURLToken];
                NSLog(@"********** url %@ ********",url);
                [[UIApplication sharedApplication] openURL:url];
                
            }];
        }];
    }];
    [self.backgroundQueue addOperation:operation];
    return operation;
    
}

- (NSBlockOperation*)embededSendingTagAndSendWorkFlowForTemplateWithID:(NSString*)templateID forRecipient:(DSAPIRecipient*)recipient withEmailSubject:(NSString*)subject emailBlurb:(NSString*)blurb completionBlock:(DSAPICompletionBlock)completionBlock {
    [self fetchBaseURLIfRequired];//fetch the baseURL and accountID if its not already fetched by another API.
    if(!accountId.length || !baseUrl.length)
        return nil;
    
    if(!templateID.length) {
        NSLog(@"%s templateID cannot be blank",__FUNCTION__);
        if(completionBlock) {
            completionBlock(nil,[[NSError alloc] initWithDomain:@"" code:0 userInfo:@{@"error":@"templateID cannot be blank"}]);
        }
        return nil;
    }
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        ///////////////////////////////////////////////////////////////////////////////////////
        // STEP 2 - Create Envelope via Template and save as a draft (i.e. don't send)
        ///////////////////////////////////////////////////////////////////////////////////////
        // append "/envelopes" URI to your baseUrl and use as endpoint for signature request call
        NSString *envelopesURL = [NSString stringWithFormat:@"%@/envelopes",baseUrl];
        NSMutableURLRequest *signatureRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:envelopesURL]];
        [signatureRequest setHTTPMethod:@"POST"];
        [signatureRequest setURL:[NSURL URLWithString:envelopesURL]];
        // construct a JSON formatted signature request body (multi-line for readability)
        NSDictionary *signatureRequestData = @{@"accountId": accountId,
                                               @"emailSubject" : @"Embedded Sending API call",
                                               @"emailBlurb" : @"email body goes here",
                                               @"templateId" : templateID,
                                               @"templateRoles" : [NSArray arrayWithObjects: @{@"email":recipient.email, @"name": recipient.fullName, @"roleName": recipient.roleName, @"clientUserId": @"1" }, nil ],
                                               @"status" : @"created"
                                               };
        // convert request body into an NSData object
        NSData* data = [[self jsonStringFromObject:signatureRequestData] dataUsingEncoding:NSUTF8StringEncoding];
        // attach body to the request
        [signatureRequest setHTTPBody:data];
        // authentication and content-type headers
        [signatureRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
        [signatureRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        // Create a draft envelope...
        [NSURLConnection sendAsynchronousRequest:signatureRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *envelopeResponse, NSData *envelopeData, NSError *envelopeError) {
            NSError *jsonError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:envelopeData options:kNilOptions error:&jsonError];
            NSLog(@"Envelope created as a draft. Envelope info is: \n%@\n", responseDictionary);
            NSString *envelopeId = responseDictionary[@"envelopeId"];
            ///////////////////////////////////////////////////////////////////////////////////////
            // STEP 3 - Get the Embedded Sending View (aka "tag-and-send" view)
            ///////////////////////////////////////////////////////////////////////////////////////
            NSString *embeddedURL = [NSString stringWithFormat:@"%@/envelopes/%@/views/sender", baseUrl, envelopeId];
            NSMutableURLRequest *embeddedRequest = [[NSMutableURLRequest alloc] init];
            [embeddedRequest setHTTPMethod:@"POST"];
            [embeddedRequest setURL:[NSURL URLWithString:embeddedURL]];
            // simply set the returnUrl in the request body (user is directed here after signing)
            NSDictionary *embeddedRequestData = @{@"returnUrl":returnURI};
            // convert request body into an NSData object
            NSData* data = [[self jsonStringFromObject:embeddedRequestData] dataUsingEncoding:NSUTF8StringEncoding];
            // attach body to the request
            [embeddedRequest setHTTPBody:data];
            // jsonStringFromObject() function defined below...
            [embeddedRequest setValue:[self jsonStringFromObject:authenticationHeader] forHTTPHeaderField:@"X-DocuSign-Authentication"];
            // also set the Content-Type header (other accepted type is application/xml)
            [embeddedRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            //*** make an asynchronous web request
            [NSURLConnection sendAsynchronousRequest:embeddedRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *embeddedResponse, NSData *embeddedData, NSError *embeddedError) {
                if (embeddedError) { // succesful POST returns status 201
                    NSLog(@"Error sending request %@. Got Response %@ Error is: %@", embeddedRequest, embeddedResponse, embeddedError);
                    return;
                }
                NSError *jsonError = nil;
                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:embeddedData options:kNilOptions error:&jsonError];
                NSString *embeddedURLToken = responseDictionary[@"url"];
                if(completionBlock) {
                    completionBlock(responseDictionary,envelopeError);
                }
                
                //--- display results
                NSLog(@"URL token created - please navigate to the following URL to start the embedded sending workflow:\n\n%@\n\n", embeddedURLToken);
                NSURL *url = [NSURL URLWithString:embeddedURLToken];
                NSLog(@"********** url %@ ********",url);
                [[UIApplication sharedApplication] openURL:url];
            }];
        }];    
    }];
    [self.backgroundQueue addOperation:operation];    
    return operation;
    
}



@end
