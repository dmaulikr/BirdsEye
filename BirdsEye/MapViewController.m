//
//  MapViewController.m
//  BirdsEye
//
//  Created by Lee on 9/24/16.
//  Copyright © 2016 Shanelle's Marauders. All rights reserved.
//

#import "MapViewController.h"
#import <MapBox/Mapbox.h>
#import "CustomAnnotationView.h"
#import "RequestModule.h"
#import "LocationModule.h"
#import "Storage.h"

#define WAIT_BETWEEN_PINGS (5)

@interface MapViewController ()

@property (strong, nonatomic) IBOutlet MGLMapView *mapView;

@property (weak) NSTimer *repeatingTimer;


@property (strong, nonatomic) NSMutableDictionary *userDict;
@property (strong, nonatomic) NSMutableDictionary *teamMap;

@property (strong, nonatomic) RequestModule *request;
@property (strong, nonatomic) LocationModule *location;

@property (nonatomic, weak) UILabel *speedLabel;

@property (nonatomic) CALayer *spinnyRadar;
@property (nonatomic) NSMutableArray *annotationViews;
@end

@implementation MapViewController

- (NSMutableArray *)annotationViews {
    if (!_annotationViews) {
        _annotationViews = [NSMutableArray array];
    }
    return _annotationViews;
}

// shared module for use in other classes
+ (MapViewController *)sharedModule {
    static MapViewController *module = nil;
    if (!module) {
        module = [[self alloc] init];
    }
    return module;
}

- (void)updateSpeedLabel {
    self.speedLabel.text = [NSString stringWithFormat:@"%g, %g", [[LocationModule sharedModule] speed], [[LocationModule sharedModule] uncertaintyRadius]];
}

#define RADAR_HEIGHT (350)
#define RADAR_WIDTH (90)

- (CALayer *)spinnyRadar {
    if (!_spinnyRadar) {
        CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
        gradientLayer.colors = @[(id)[[UIColor clearColor] CGColor], (id)[[UIColor colorWithRed:0 green:1 blue:0 alpha:0.5] CGColor], (id)[[UIColor colorWithRed:0 green:1 blue:0 alpha:0.8] CGColor]];
        CGSize screenSize = self.view.bounds.size;
        gradientLayer.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width/2-RADAR_WIDTH/2, screenSize.height/2 - RADAR_HEIGHT/2, RADAR_WIDTH, RADAR_HEIGHT);
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1, 0);
        gradientLayer.locations = @[@0.0, @0.85, @1.0];
        gradientLayer.anchorPoint = CGPointMake(1, 1);

        CAShapeLayer *triangleMask = [[CAShapeLayer alloc] init];
        UIBezierPath *trianglePath = [UIBezierPath bezierPath];
        [trianglePath moveToPoint:CGPointMake(RADAR_WIDTH, RADAR_HEIGHT)];
        [trianglePath addLineToPoint:CGPointMake(RADAR_WIDTH, 0)];
        double angle = atan2(RADAR_WIDTH, RADAR_HEIGHT);
        [trianglePath addArcWithCenter:CGPointMake(RADAR_WIDTH, RADAR_HEIGHT) radius:RADAR_HEIGHT startAngle:3*M_PI_2 endAngle:3*M_PI_2-angle clockwise:NO];
        [trianglePath addLineToPoint:CGPointMake(RADAR_WIDTH, RADAR_HEIGHT)];
        triangleMask.path = [trianglePath CGPath];
        triangleMask.fillColor = [UIColor blackColor].CGColor;
        
        // the transparent parts of triangle-mask can
        [gradientLayer setMask:triangleMask];
        _spinnyRadar = gradientLayer;
    }
    return _spinnyRadar;
}

#define BLUE_DOT_RADIUS (10)
#define BLUE_DOT_BORDER (12)

- (void)addUserBlueDot {
    CGSize screenSize = self.view.bounds.size;
    UIView *blueDot = [[UIView alloc] initWithFrame:CGRectMake(screenSize.width/2 - BLUE_DOT_BORDER/2, screenSize.height/2 - BLUE_DOT_BORDER/2, BLUE_DOT_BORDER, BLUE_DOT_BORDER)];
    UIBezierPath *dotPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(BLUE_DOT_BORDER/2, BLUE_DOT_BORDER/2) radius:BLUE_DOT_RADIUS/2 startAngle:0 endAngle:2*M_PI clockwise:YES];
    UIBezierPath *borderPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(BLUE_DOT_BORDER/2, BLUE_DOT_BORDER/2) radius:BLUE_DOT_BORDER/2 startAngle:0 endAngle:2*M_PI clockwise:YES];
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    [layer setPath:[dotPath CGPath]];
    [layer setFillColor:[[UIColor blueColor] CGColor]];
    CAShapeLayer *borderLayer = [[CAShapeLayer alloc] init];
    [borderLayer setFillColor:[[UIColor colorWithRed:0.3 green:0.3 blue:1 alpha:1] CGColor]];
    [borderLayer setPath:[borderPath CGPath]];
    [blueDot.layer addSublayer:borderLayer];
    [blueDot.layer addSublayer:layer];
    [self.view addSubview:blueDot];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UILabel *speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 700, 100)];
    [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSpeedLabel) userInfo:nil repeats:YES] fire];
    speedLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:speedLabel];
    self.speedLabel = speedLabel;
    
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    //view.backgroundColor = [UIColor whiteColor];
    
    [view.layer addSublayer:[self spinnyRadar]];
    [self.view addSubview:view];
    // Do any additional setup after loading the view, typically from a nib.
    
    //test commit
    //setup userDict
    self.userDict = [[NSMutableDictionary alloc] init];
    self.teamMap = [[NSMutableDictionary alloc] init];
    
    self.request = [RequestModule sharedModule];
    self.location = [LocationModule sharedModule];
    //start updating location
    [self.location startUpdatingLocation];
    
    
    [self.mapView setScrollEnabled:false];
    [self.mapView setZoomEnabled:false];
    [self.mapView setPitchEnabled:false];
    [self.mapView setRotateEnabled:false];
    [self.mapView setZoomLevel:(double)18];
    //[self.mapView setMaximumZoomLevel:(double)25];
    //[self.mapView setMinimumZoomLevel:(double)15];
    
//    //testing points
//    // Specify coordinates for our annotations.
//    CLLocationCoordinate2D coordinates[] = {
//        CLLocationCoordinate2DMake(0, 33),
//        CLLocationCoordinate2DMake(0, 66),
//        CLLocationCoordinate2DMake(0, 99),
//    };
//    NSUInteger numberOfCoordinates = sizeof(coordinates) / sizeof(CLLocationCoordinate2D);
//    
//    // Fill an array with point annotations and add it to the map.
//    NSMutableArray *pointAnnotations = [NSMutableArray arrayWithCapacity:numberOfCoordinates];
//    for (NSUInteger i = 0; i < numberOfCoordinates; i++) {
//        CLLocationCoordinate2D coordinate = coordinates[i];
//        MGLPointAnnotation *point = [[MGLPointAnnotation alloc] init];
//        point.coordinate = coordinate;
//        point.title = [NSString stringWithFormat:@"%.f, %.f", coordinate.latitude, coordinate.longitude];
//        [pointAnnotations addObject:point];
//    }
//    
//    [self.mapView addAnnotations:pointAnnotations];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //setup the timer
    [self addUserBlueDot];
    [self updateCoordinates:nil];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:WAIT_BETWEEN_PINGS
                                                      target:self selector:@selector(updateCoordinates:)
                                                    userInfo:nil repeats:YES];
    self.repeatingTimer = timer;
}

- (BOOL)mapView:(MGLMapView *)mapView annotationCanShowCallout:(id <MGLAnnotation>)annotation {
    // Always try to show a callout when an annotation is tapped.
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateCoordinates:(NSTimer*)timer {
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake([self.location latitude], [self.location longitude])];
    //call shanelle's update function here, the rest of this probably goes in a callback
    [self.request pingInfo:[[Storage sharedModule] userId] andGroupID:[[Storage sharedModule] groupId] andReturningData:^(NSDictionary *newDict) {
        if (newDict) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self updateUserDict:newDict];
            }];
        }

    }];
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithFloat:WAIT_BETWEEN_PINGS]
                     forKey:kCATransactionAnimationDuration];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:@"linear"]];
    CGAffineTransform transformation = self.spinnyRadar.affineTransform;
    [self.spinnyRadar setAffineTransform:CGAffineTransformRotate(transformation, 1)];
    // Perform the animations
    [CATransaction commit];
    //temp
//    NSDictionary *newDict = [[NSDictionary alloc] init];
//    
//    [self updateUserDict:newDict];
    
    //sometimes were probably going to want to make annotations visible or invisible, we can do that here
    
}

- (MGLAnnotationView *)mapView:(MGLMapView *)mapView viewForAnnotation:(id <MGLAnnotation>)annotation {
    // This example is only concerned with point annotations.
    if (![annotation isKindOfClass:[MGLPointAnnotation class]]) {
        return nil;
    }
    
    // Use the point annotation’s longitude value (as a string) as the reuse identifier for its view.
    NSString *reuseIdentifier = [NSString stringWithFormat:@"%f", annotation.coordinate.longitude];
    
    // For better performance, always try to reuse existing annotations.
    CustomAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];
    /*CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 2;
    animation.fromValue = @1.0f;
    animation.toValue = @0.0f;
*/
    
    // If there’s no reusable annotation view available, initialize a new one.
    if (!annotationView) {
        annotationView = [[CustomAnnotationView alloc] initWithReuseIdentifier:reuseIdentifier];
        annotationView.frame = CGRectMake(0, 0, 12, 12);
        
        [self.annotationViews addObject:annotationView];
    }
    
    // Set the annotation view’s background color to a value determined by its longitude.
    NSArray *temp = [_userDict allKeysForObject:annotation];
    NSString *userId = [temp lastObject];
    
    if ([_teamMap[userId] intValue] == [[Storage sharedModule] teamId]) {
        annotationView.backgroundColor = [UIColor colorWithRed:0 green:1 blue:.5 alpha:1];
        annotationView.layer.borderColor = [UIColor yellowColor].CGColor;
    } else {
        CGFloat hue = (CGFloat)1;
        annotationView.backgroundColor = [UIColor colorWithHue:hue saturation:0.5 brightness:1 alpha:1];
        annotationView.layer.borderColor = [UIColor redColor].CGColor;
    }
    
    //[annotationView.layer addAnimation:animation forKey:@"opacity"];
    
    
    return annotationView;
}

-(void)updateUserDict:(NSDictionary*) newDict {
    NSArray *array = newDict[@"locations"];
    for (NSDictionary *newData in array) {
        //if user exists in the existing data, update them
        MGLPointAnnotation *point;
        if ((point = _userDict[newData[@"id"]]) != NULL) {
            point.coordinate = CLLocationCoordinate2DMake([newData[@"latitude"] doubleValue], [newData[@"longitude"] doubleValue]);
        } else {
            //create them
            point = [[MGLPointAnnotation alloc] init];
            [_userDict setObject:point forKey:newData[@"id"]];
            [_teamMap setObject:newData[@"team"] forKey:newData[@"id"]];
            NSLog(@"adding user %@", newData[@"id"]);
            point.coordinate = CLLocationCoordinate2DMake([newData[@"latitude"] doubleValue], [newData[@"longitude"] doubleValue]);
            [self.mapView addAnnotation:point];
        }
    }
    
    for (UIView *annotation in self.annotationViews) {
        annotation.alpha = 1;
    }
    [UIView animateWithDuration:2 animations:^{
        for (UIView *annotation in self.annotationViews) {
            annotation.alpha = 0;
        }
    }];
    
    
    //remove users that are no longer sending location data
    // this functinonality is not implemented on the backend
    
    
//    for(id key in _userDict) {
//        MGLPointAnnotation *point = [_userDict objectForKey:key];
//        BOOL found = false;
//        for (NSDictionary *newData in array) {
//            if (newData[@"id"] == key) {
//                found = true;
//            }
//        }
//        if (!found) {
//            NSLog(@"removing user %@", key);
//            [self.mapView removeAnnotation:point];
//            [_userDict removeObjectForKey:key];
//        }
//    }
}

@end
