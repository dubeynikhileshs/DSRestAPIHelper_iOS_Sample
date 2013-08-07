//
//  DSAPIHelperUnitTest.m
//  DSAPIHelperUnitTest
//
//  Created by nik on 07/08/13.
//  Copyright (c) 2013 CloudSpokes. All rights reserved.
//

#import "DSAPIHelperUnitTest.h"
#import "DSAPIHelper.h"
#import "APIConfig.h"

#define COMPLETION_BLOCK [self completionBlockForRequest:@(__func__)]

@interface DSAPIHelperUnitTest(){
    DSAPIHelper* sharedHelper;
}

@end

@implementation DSAPIHelperUnitTest

- (void)setUp
{
    [super setUp];
    
    sharedHelper = [DSAPIHelper sharedHelper];
    sharedHelper.userId = kUserId;
    sharedHelper.integratorKey = kIntegratorKey;
    sharedHelper.password = kPassword;
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (DSAPICompletionBlock)completionBlockForRequest:(NSString*)requestName {
    DSAPICompletionBlock block = ^(NSDictionary* response,NSError* error) {
        NSLog(@"%@::completionBlock error %@ \nresponse %@",requestName,error,response);
    };
    return block;
}


- (void)testGetEnvelopeInfo {
    [sharedHelper envelopeInfoForEnvelopeId:@"c94e6410-0bd0-4652-bef8-8e500e347e9b" completionBlock:COMPLETION_BLOCK];
}

- (void)testEmbeddedDocuSignConsole {
    [sharedHelper embeddedDocuSignConsoleWithCompletionBlock:COMPLETION_BLOCK];
}

- (void)testFetchRecipientInfoForEnvelopeId {
    [sharedHelper recipientInfoForEnvelopeId:@"c94e6410-0bd0-4652-bef8-8e500e347e9b" completionBlock:COMPLETION_BLOCK];
}


- (void)testRequestSignatureOnDocument {
    DSAPIRecipient* recipient = Init(DSAPIRecipient);
    recipient.fullName = @"John Smith";
    recipient.email = @"testtryfoo@gmail.com";
    [sharedHelper requestSignatureOnDocument:@"TestDocument.docx" toRecipient:recipient withEmailSubject:@"Signature Request on Document API call" emailBlurb:@"email body" completionBlock:COMPLETION_BLOCK];
}

- (void)testFetchStatusOfEnvelopesWithcompletionBlock {
    [sharedHelper statusOfEnvelopesWithcompletionBlock:COMPLETION_BLOCK];
}

- (void)testDownloadEnvelopeInfo {
    [sharedHelper documentInfoAndDownloadDocumentsForEnvelopeId:@"c94e6410-0bd0-4652-bef8-8e500e347e9b" completionBlock:COMPLETION_BLOCK];
}

- (void)testEmbededSigningForTemplateWithID{
    DSAPIRecipient* recipient = Init(DSAPIRecipient);
    recipient.fullName = @"John Smith";
    recipient.email = @"testtryfoo@gmail.com";
    recipient.roleName = @"Signer";
    
    [sharedHelper embededSigningForTemplateWithID:kTemplateId forRecipient:recipient withEmailSubject:@"embededSigningForTemplateWithID" emailBlurb:@"embededSigningForTemplateWithID From iOS" completionBlock:COMPLETION_BLOCK ];
}

- (void)testEmbededSigningTagAndSendForTemplateWithID{
    DSAPIRecipient* recipient = Init(DSAPIRecipient);
    recipient.fullName = @"John Smith";
    recipient.email = @"testtryfoo@gmail.com";
    recipient.roleName = @"Signer";
    
    [sharedHelper embededSendingTagAndSendWorkFlowForTemplateWithID:kTemplateId forRecipient:recipient withEmailSubject:@"embededSigningForTemplateWithID" emailBlurb:@"embededSigningForTemplateWithID From iOS" completionBlock:COMPLETION_BLOCK ];
}

//STFail(@"Unit tests are not implemented yet in DSAPIHelperUnitTest");

@end
