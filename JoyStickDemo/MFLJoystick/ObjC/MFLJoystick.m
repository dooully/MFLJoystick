//
//  MFJoystick.m
//  
//
//  Created by teejay on 5/14/13.
//  Copyright (c) 2013 teejay. All rights reserved.
//

#import "MFLJoystick.h"

#define TO_DEGREES(degrees)(degrees * 180 / M_PI)

@interface MFLJoystick ()

@property BOOL isTouching;

@property CGFloat moveViscosity;
@property CGFloat smallestPossible;
@property CGPoint defaultPoint;

@property UIImageView *bgImageView;
@property UIButton *thumbImageView;
@property UIView *handle;
@property CGFloat bgRadius;

@end

@implementation MFLJoystick

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self sharedInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self sharedInit];
    }
    
    return self;
}

- (void)sharedInit
{
    [self setDefaultValues];
    [self roundView:self toDiameter:self.bounds.size.width];

    _bgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width,
                                                                 self.bounds.size.height)];
    [self roundView:_bgImageView toDiameter:_bgImageView.bounds.size.width];
    [self addSubview:_bgImageView];

    [self makeHandle];
    [self animate];
    [self notifyDelegate];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSLog(@"[layoutSubviews]");
    
    _bgImageView.frame = self.bounds;
    
    CGRect thumbRect = CGRectMake(0, 0, self.bounds.size.width * 0.7, self.bounds.size.height * 0.7);
    
    self.handle.frame = thumbRect;
    self.thumbImageView.frame = thumbRect;
    
    [self.handle setCenter:CGPointMake(self.bounds.size.width/2,
                                       self.bounds.size.height/2)];
    
    self.thumbImageView.center = self.handle.center;
    
    self.defaultPoint = self.handle.center;
    [self notifyDelegate];
}

- (void)didMoveToSuperview
{
    if (!self.superview) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notifyDelegate) object:nil];
    }
}

- (void)setDefaultValues
{
    _moveViscosity = 4;
    _smallestPossible = 0.09;
    _updateInterval = 1.0/45;
}

- (void)makeHandle
{
    CGRect thumbRect = CGRectMake(0, 0, self.bounds.size.width * 0.7, self.bounds.size.height * 0.7);
    
    self.handle = [[UIView alloc] initWithFrame:thumbRect];
    [self.handle setCenter:CGPointMake(self.bounds.size.width/2,
                                       self.bounds.size.height/2)];
    self.defaultPoint = self.handle.center;
    [self roundView:self.handle toDiameter:self.handle.bounds.size.width];
    [self addSubview:self.handle];
    self.handle.userInteractionEnabled = NO;
    
    self.thumbImageView = [[UIButton alloc] initWithFrame:self.handle.frame];
    self.thumbImageView.userInteractionEnabled = NO;
    [self addSubview:self.thumbImageView];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    [UIView animateWithDuration:.2 animations:^{
//        self.alpha = 1;
//    }];
    
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *myTouch = [[touches allObjects] objectAtIndex:0];
    CGPoint currentPos = [myTouch locationInView: self];
    
    //else
    CGPoint selfCenter = CGPointMake(self.bounds.origin.x+self.bounds.size.width/2,
                                     self.bounds.origin.y+self.bounds.size.height/2);
    self.bgRadius = (self.bounds.size.width - self.handle.bounds.size.width) / 2;
    
    if (DistanceBetweenTwoPoints(currentPos, selfCenter) > self.bgRadius) {
        double vX = currentPos.x - selfCenter.x;
        double vY = currentPos.y - selfCenter.y;
        double magV = sqrt(vX*vX + vY*vY);
        currentPos.x = selfCenter.x + vX / magV * self.bgRadius;
        currentPos.y = selfCenter.y + vY / magV * self.bgRadius;
    }
    
    [UIView animateWithDuration:.1 animations:^{
        self.thumbImageView.center = currentPos;
    }];
    
    self.handle.center = currentPos;
    self.isTouching = TRUE;

}

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint localPoint = [self convertPoint:point fromView:self];
    for (UIView *subview in self.subviews) {
        if ([subview pointInside:localPoint withEvent:event]) {
            return YES;
        }
    }
    return NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//    [UIView animateWithDuration:.4 animations:^{
//        self.alpha = 0.1;
//    }];
    [self.delegate joystick:self didUpdate:CGPointZero];
    
    self.isTouching = FALSE;
}

- (BOOL)checkPoint:(CGPoint)point isInCircle:(CGPoint)center withRadius:(CGFloat)radius
{
    return (powf(point.x-center.x, 2) + powf(point.y-center.y, 2) < powf(radius, 2));
}

- (void)animate
{
    if (!self.isTouching)
    {
        //move the handle back to the default position
        CGFloat newX = self.handle.center.x;
        CGFloat newY = self.handle.center.y;
        CGFloat dx = fabsf(newX - self.defaultPoint.x);
        CGFloat dy = fabsf(newY - self.defaultPoint.y);
        
        if (self.handle.center.x > self.defaultPoint.x)
        {
            newX = self.handle.center.x - dx/self.moveViscosity;
        } else if (self.handle.center.x < self.defaultPoint.x) {
            newX = self.handle.center.x + dx/self.moveViscosity;
        }
        
        if (self.handle.center.y > self.defaultPoint.y) {
            newY = self.handle.center.y - dy/self.moveViscosity;
        } else if (self.handle.center.y < self.defaultPoint.y) {
            newY = self.handle.center.y + dy/self.moveViscosity;
        }

        if (fabsf(dx/self.moveViscosity) < self.smallestPossible &&
            fabsf(dy/self.moveViscosity) < self.smallestPossible)
        {
            newX = self.defaultPoint.x;
            newY = self.defaultPoint.y;
        }
        
        self.handle.center = CGPointMake(newX, newY);
        self.thumbImageView.center = self.handle.center;
    }
    [self performSelector:@selector(animate) withObject:nil afterDelay:1/45];
}

- (void)notifyDelegate
{
    if (self.isTouching)
    {
        CGPoint degreeOfPosition = CGPointMake((self.handle.frame.origin.x/self.handle.frame.size.width-.55)*2,
                                               (self.handle.frame.origin.y/self.handle.frame.size.height-.55)*2);
        [self.delegate joystick:self didUpdate:degreeOfPosition];
        
        
        [self.delegate joystick:self angle:[self getAngle] strength:[self getStrength]];
    }
    
    [self performSelector:@selector(notifyDelegate) withObject:nil afterDelay:self.updateInterval];

}

- (void)setMovementUpdateInterval:(CGFloat)interval
{
    if (interval <= 0) {
        self.updateInterval = 1.0;
    } else {
        self.updateInterval = interval;
    }
}
- (void)setMoveViscosity:(CGFloat)mv andSmallestValue:(CGFloat)sv
{
    self.moveViscosity = mv;
    self.smallestPossible = sv;
}

- (void)setThumbImage:(UIImage *)thumbImage andSelectImage:(UIImage *)thumbSelectImage andBGImage:(UIImage *)bgImage;
{
    [self.thumbImageView setImage:thumbImage forState:UIControlStateNormal];
    [self.thumbImageView setImage:thumbSelectImage forState:UIControlStateSelected];
//    self.thumbImageView.highlightedImage = thumbHighImage;
    self.bgImageView.image = bgImage;
}

- (void)roundView:(UIView *)roundedView toDiameter:(float)newSize
{
    CGPoint saveCenter = roundedView.center;
    CGRect newFrame = CGRectMake(roundedView.frame.origin.x, roundedView.frame.origin.y, newSize, newSize);
    roundedView.frame = newFrame;
    roundedView.layer.cornerRadius = newSize / 2.0;
    roundedView.center = saveCenter;
}

- (void) setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.userInteractionEnabled = enabled;
    self.thumbImageView.enabled = enabled;
}

- (int) getAngle {
    int angle = (int)TO_DEGREES(atan2f(self.defaultPoint.y - self.handle.center.y, self.defaultPoint.x - self.handle.center.x));
    return angle < 0 ? angle + 360 : angle;
}

- (float) getStrength {
    return (100 * sqrtf((self.defaultPoint.x - self.handle.center.x) * (self.defaultPoint.x - self.handle.center.x) + (self.defaultPoint.y - self.handle.center.y) * (self.defaultPoint.y - self.handle.center.y))) / self.bgRadius;
}

- (void) setSelected:(BOOL)selected {
    [super setEnabled:selected];
    
    self.thumbImageView.selected = selected;
}

#pragma mark Geometry Methods

CGFloat DistanceBetweenTwoPoints(CGPoint point1,CGPoint point2)
{
    CGFloat dx = point2.x - point1.x;
    CGFloat dy = point2.y - point1.y;
    CGFloat distance = sqrt(dx*dx + dy*dy);

    return sqrt(dx*dx + dy*dy);
};

@end
