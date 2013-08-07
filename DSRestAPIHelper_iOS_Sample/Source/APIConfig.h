//
//  APIConfig.h
//  DocuSignRestAPIHelper
//
//  Created by nik on 04/08/13.
//  Copyright (c) 2013 CloudSpokes. All rights reserved.
//

#ifndef DocuSignFramework_ObjC_APIConfig_h
#define DocuSignFramework_ObjC_APIConfig_h

#define kAppName [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleDisplayName"]

#define Init(arg) [[NSClassFromString(NSStringFromClass([arg class])) alloc] init]



static NSString* const kIntegratorKey = @"XORI-84155a30-597a-4821-918a-40551d71dcff";
static NSString* const kUserId =        @"dubeynikhileshs@gmail.com";
static NSString* const kPassword =      @"nick2468";

static NSString* const kTemplateId =    @"5AB61121-DBEF-4403-BD2C-77B6E2E427F0";

#endif
