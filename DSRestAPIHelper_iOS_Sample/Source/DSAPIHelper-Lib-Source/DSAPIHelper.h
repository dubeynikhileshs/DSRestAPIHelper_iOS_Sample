//
//  DSAPIHelper.h
//  DocuSignRestAPIHelper
//
//  Created by nik on 04/08/13.
//  Copyright (c) 2013 CloudSpokes. All rights reserved.
//

static NSString* const returnURI = @"dsrestapi://redirecturi";

@class DSAPIHelper;

/*
 DSAPIRecipient
 This Class represents the Recipient model object which is passed to several Docusign rest API.
 */
@interface DSAPIRecipient : NSObject
/*fullName of the recipient.*/
@property(nonatomic,strong) NSString* fullName;

/*Email of the recipient.*/
@property(nonatomic,strong) NSString* email;

/*RoleName of the recipient.*/
@property(nonatomic,strong) NSString* roleName;
@end

/*Completion block which is invokes when an API receives and error or a valid response.*/
typedef void (^DSAPICompletionBlock)(NSDictionary*response, NSError* error);

/*
 DSAPIHelper
 This Class exposes helper methods which can be used to interact with DocuSign Rest API v2.
 For more info about DocuSignRestAPIs v2 please refer http://www.docusign.com/sites/default/files/REST_API_Guide_v2.pdf
 */

@interface DSAPIHelper : NSObject

/*userId of your docusign account */
@property(nonatomic,strong) NSString* userId ;

/*A valid integrator key present in your docusign account.
 An Integrator Key is a Unique Identifier for each DocuSign integration. It is used (and required) for all API calls (SOAP or REST) to any DocuSign service.
 */
@property(nonatomic,strong) NSString* integratorKey;

/*Password of your docusign account*/
@property(nonatomic,strong) NSString* password;




/*
 Request a signature on a document referenced through a template.
This method demonstrates how to send a signature request from an existing template. A template is an object that holds document(s) and recipient(s), and they are useful when you have common signature requests that you send out. For instance, you have a document that you need to get signed once a month by a given recipient. Or maybe you have a common form that new users on your site sign. Using templates you can create templates roles and assign your recipients to those, which in turn inherits all the signature and information tabs that have been setup for that role.
 */
- (NSBlockOperation*)requestSignatureFromTemplateWithID:(NSString*)templateID forRecipient:(DSAPIRecipient*)recipient withEmailSubject:(NSString*)subject emailBlurb:(NSString*)blurb completionBlock:(DSAPICompletionBlock)completionBlock;



/*
 This method demonstrates how to retrieve envelope information for an envelope that has been sent for signature or saved as a draft. An envelope is analogous to a physical envelope, and can contain document(s), recipient(s), and a routing order (i.e. when first person is done signing the document then gets routed to the next recipient). Typically, the type of envelope information retrieved is status (has the envelope been sent, delivered, signed, etc.) as well as the time and date of the action. 
 */
- (NSBlockOperation*)envelopeInfoForEnvelopeId:(NSString*)envelopeID completionBlock:(DSAPICompletionBlock)completionBlock;


/*
 Retrieve recipient information of an envelope.
 Envelopes have statuses and so do Recipients. For instance, you can have an envelope that has two recipients where the first recipient has signed the document(s), but the second recipient has declined to sign. In this case the first recipient's status would be signed, the second recipient status is declined, and the status of the whole Envelope is declined (since one recipient has declined). This method demonstrates how to retrieve recipient information for a given envelope. 
 */
- (NSBlockOperation*)recipientInfoForEnvelopeId:(NSString*)envelopeId completionBlock:(DSAPICompletionBlock)completionBlock;


/*
requestSignatureFromTemplateWithID demonstrated how to send a document using a Template. requestSignatureOnDocument demonstrates how to send a document for signature without the use of templates. Templates are useful when you want your recipients to inherit the signature and information tabs that you've setup in previous requests. However you can not save a template without a document, so if the underlying document changes for each request then you might not want to use templates. Instead, you want to send a multipart/form-data request with your document(s) specified in the body of the request, and through the API call you can specify all of your recipient and tabs information. It should be noted that if you request a signature on a document but save the Envelope as a draft (i.e. status = created) instead of sending right away, that has the effect of simply uploading your document(s) into the DocuSign system in a new Envelope.
 */
- (NSBlockOperation*)requestSignatureOnDocument:(NSString*)documentName  toRecipient:(DSAPIRecipient*)recipient withEmailSubject:(NSString*)subject emailBlurb:(NSString*)blurb completionBlock:(DSAPICompletionBlock)completionBlock;
;


/*
 This is similar to envelopeInfoForEnvelopeId however, it shows you how to get information on a set of envelopes using a date and status filter. This particular example sets a date and status filter 7 days back and for all envelope statuses (note the query string that gets appended to the url in the second request).
 */
- (NSBlockOperation*)statusOfEnvelopesWithcompletionBlock:(DSAPICompletionBlock)completionBlock;


/*
 This method demonstrates how to request information on the documents contained in an envelope, and it also demonstrates how to download those actual documents to your local machine. One thing to note here is that the system automatically adds an additional document to every envelope, which is the envelope's Certificate. This Certificate document contains information about the envelope and its documentId is always the string "certificate" (as opposed to 1 or 2 for example).
 */
- (NSBlockOperation*)documentInfoAndDownloadDocumentsForEnvelopeId:(NSString*)envelopeId completionBlock:(DSAPICompletionBlock)completionBlock;


/*
 With Embedded Sending you can generate a user-authenticated URL that, when navigated to, begins the "tag-and-send" workflow of a given envelope. With embedded sending you can seamlessly integrate DocuSign functionality into your website or app. Embedded Sending is very popular with website developers, since it allows your users to use DocuSign functionality without having to leave your website. And you can control the pages your users are re-directed to once they are done tagging and sending their documents.
 */
- (NSBlockOperation*)embededSendingTagAndSendWorkFlowForTemplateWithID:(NSString*)templateID forRecipient:(DSAPIRecipient*)recipient withEmailSubject:(NSString*)subject emailBlurb:(NSString*)blurb completionBlock:(DSAPICompletionBlock)completionBlock ;


/*
 With Embedded Signing you can generate a user-authenticated URL that, when navigated to, begins the signing workflow of a given envelope. This means that you do not have to wait for any emails to arrive to sign documents. Embedded Signing is very popular with website developers, since it allows your users to use DocuSign functionality without having to leave your website. And you can even control the re-direct pages once someone is done signing, declining to sign, etc.
 */
- (NSBlockOperation*)embededSigningForTemplateWithID:(NSString*)templateID forRecipient:(DSAPIRecipient*)recipient withEmailSubject:(NSString*)subject emailBlurb:(NSString*)blurb completionBlock:(DSAPICompletionBlock)completionBlock;


/*
 With the DocuSign REST API you can automate almost all parts of the sending and signing process. Through Embedded Signing and Embedded Sending you can use URLs to initiate the signing or "tag-and-send" workflows, respectively. This walkthrough demonstrates how you can open the DocuSign UI (referred to as the Member or Admin Console) by navigating to a user-authenticated URL. From there, you can use the DocuSign UI to send and sign envelopes, change account settings, add/remove account users, and perform other tasks (given that you have the proper permissions enabled). */
- (NSBlockOperation*)embeddedDocuSignConsoleWithCompletionBlock:(DSAPICompletionBlock)completionBlock;

/*
 Returns an instance of DSAPIHelper.
 */
+ (DSAPIHelper *)sharedHelper;

/*
Fetches the baseUrl and AccountID for given userId, password and IntegratorKey and stores it in instance variable.
basURl is formatted as follows https://{server}/restapi/{apiVersion}/
and is used in future API calls as the base of the request URL.
 */
- (void)fetchBaseURLAndAccountId;
@end
