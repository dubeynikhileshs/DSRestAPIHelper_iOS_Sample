//
//  DetailViewController.m
//  DSRestAPIHelper_iOS_Sample
//
//  Created by nik on 05/08/13.
//  Copyright (c) 2013 CloudSpokes. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
@property (strong, nonatomic) IBOutlet UITextView *textView;

@end

@implementation DetailViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem* rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBtnPressed)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    self.title = @"Detail";

    _textView.editable = NO;
    _textView.text = _text;
}

- (void)doneBtnPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
