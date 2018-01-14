//
//  ViewController.h
//  VideoDeocde-objc
//
//  Created by larryhou on 14/01/2018.
//  Copyright © 2018 larryhou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewControllerObjc : UIViewController
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UILabel *loopIndicator;
@property (weak, nonatomic) IBOutlet UILabel *timeIndicator;
@end

