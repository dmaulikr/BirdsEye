//
//  ViewController.m
//  BirdsEye
//
//  Created by Lee on 9/24/16.
//  Copyright © 2016 Shanelle's Marauders. All rights reserved.
//

#import "ViewController.h"
#import "RequestModule.h"
#import "MapViewController.h"

@interface ViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIButton *joinButton;
@property (nonatomic, weak) IBOutlet UIButton *createButton;

@property (nonatomic) NSString *name;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    RequestModule* sample = [RequestModule sharedModule];


    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createGroup:(id)sender {
    UIAlertController *groupNameRequest = [UIAlertController alertControllerWithTitle:@"Enter Group Name" message:nil preferredStyle:UIAlertControllerStyleAlert];
    __block UITextField *groupNameField;
    [groupNameRequest addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Group Name";
        groupNameField = textField;
    }];
    __block UITextField *teamNumberField;
    [groupNameRequest addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Number of Teams (default 1)";
        teamNumberField = textField;
    }];
    [groupNameRequest addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
     [groupNameRequest addAction:[UIAlertAction actionWithTitle:@"Play" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         NSLog(@"Create group with name %@ number of teams %@", groupNameField.text, teamNumberField.text);
         [[RequestModule sharedModule] createGroupInfo:groupNameField.text andTeams:[teamNumberField.text intValue] andReturningData:^(NSDictionary *dict) {
             [[MapViewController sharedModule] setGroupId:[dict[@"group_id"] intValue]];
             [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                 [self performSegueWithIdentifier:@"map" sender:sender];
             }];
         }];
    }]];
    [self presentViewController:groupNameRequest animated:YES completion:nil];
}

@end
