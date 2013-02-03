//
//  ChipmunkGrabberLayer.m
//  BasicCocos2D
//
//  Created by Ian Fan on 27/08/12.
//
//

#import "ChipmunkGrabberLayer.h"

#define GRABABLE_MASK_BIT (1<<31)
#define NOT_GRABABLE_MASK (~GRABABLE_MASK_BIT)

@implementation ChipmunkGrabberLayer

+(CCScene *) scene {
	CCScene *scene = [CCScene node];
	ChipmunkGrabberLayer *layer = [ChipmunkGrabberLayer node];
	[scene addChild: layer];
  
	return scene;
}

#pragma mark -
#pragma mark ChipmunkSpace

-(void)setSpace {
  CGSize winSize = [CCDirector sharedDirector].winSize;
  
  _space = [[ChipmunkSpace alloc]init];
  [_space addBounds:CGRectMake(0, 0, winSize.width, winSize.height) thickness:60.0 elasticity:0.0 friction:1.0 layers:NOT_GRABABLE_MASK group:nil collisionType:nil];
  _space.gravity = cpv(0, -600);
  _space.damping = 0.4;
  _space.iterations = 20;
}

#pragma mark -
#pragma mark Objects

// Wasn't sure how big to make it at first.
#define SCALE ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)? 100:50)
#define THICKNESS 10.0
NSString *SCISSOR_GROUP = @"SCISSOR_GROUP";

-(void)setObjects {
  // Add Scissor
  cpVect offsetAll = cpv(0, 0);
  
  NSMutableArray *scissorBodyMArray = [[NSMutableArray alloc]init];
  
  int scissorHeightAmount = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)? 6:4;
  
  for (int i=0; i<scissorHeightAmount*2; i++) {
    cpFloat mass = 2.0;
    
    cpFloat moment = cpMomentForBox(mass, 2*SCALE+THICKNESS, THICKNESS);
    ChipmunkBody *body = [_space addBody:[ChipmunkBody bodyWithMass:mass andMoment:moment]];
    body.pos = cpvadd(cpv(SCALE*((int)i/2), SCALE*((int)i/2)), offsetAll);
    body.angle = i%2==0? 0:M_PI_2;
    
    NSLog(@"sciBody.pos = %f, %f",body.pos.x,body.pos.y);
    NSLog(@"sciBody.angle = %f",body.angle);
    
    ChipmunkShape *shape = [_space addShape:[ChipmunkPolyShape boxWithBody:body width:2*SCALE+THICKNESS height:THICKNESS]];
    shape.elasticity = 0.0;
    shape.friction = 1.0;
    shape.group = SCISSOR_GROUP;
    
    [scissorBodyMArray addObject:body];
  }
  
  int maxCount = [scissorBodyMArray count];
  for (int i=0; i<maxCount; i+=2) {
    // Add PivotJoint
    {
    if (i+1<maxCount) {
      [_space addConstraint:[ChipmunkPivotJoint pivotJointWithBodyA:[scissorBodyMArray objectAtIndex:i] bodyB:[scissorBodyMArray objectAtIndex:i+1] pivot:cpvadd(cpv(SCALE*((int)i/2), SCALE*((int)i/2)), offsetAll)]];
    }
    
    if (i+2<maxCount) {
      [_space addConstraint:[ChipmunkPivotJoint pivotJointWithBodyA:[scissorBodyMArray objectAtIndex:i+1] bodyB:[scissorBodyMArray objectAtIndex:i+2] pivot:cpvadd(cpv(SCALE*((int)i/2), SCALE*((int)i/2+1)), offsetAll)]];
    }
    
    if (i+3<maxCount) {
      [_space addConstraint:[ChipmunkPivotJoint pivotJointWithBodyA:[scissorBodyMArray objectAtIndex:i] bodyB:[scissorBodyMArray objectAtIndex:i+3] pivot:cpvadd(cpv(SCALE*((int)i/2+1), SCALE*((int)i/2)), offsetAll)]];
    }
    }
    
    // Add RotaryLimitJoint
    {
    if (i+2<maxCount) {
      [_space addConstraint:[ChipmunkRotaryLimitJoint rotaryLimitJointWithBodyA:[scissorBodyMArray objectAtIndex:i] bodyB:[scissorBodyMArray objectAtIndex:i+1] min:0.3*M_PI max:0.9*M_PI]];
    }
    }
  }
  
  // Add Handles
  {
	cpFloat handleSize = 30.0;
  
	[_space add:[ChipmunkCircleShape circleWithBody:[scissorBodyMArray objectAtIndex:0] radius:handleSize offset:cpv(-SCALE, 0)]];
	[_space add:[ChipmunkCircleShape circleWithBody:[scissorBodyMArray objectAtIndex:1] radius:handleSize offset:cpv(-SCALE, 0)]];
	[_space add:[ChipmunkCircleShape circleWithBody:[scissorBodyMArray objectAtIndex:[scissorBodyMArray count]-1] radius:handleSize offset:cpv(SCALE, 0)]];
	[_space add:[ChipmunkCircleShape circleWithBody:[scissorBodyMArray objectAtIndex:[scissorBodyMArray count]-2] radius:handleSize offset:cpv(SCALE, 0)]];
  }
  
  /*
  ChipmunkShape *gripperShape = [_space add:[ChipmunkPolyShape boxWithBody:[scissorBodyMArray objectAtIndex:maxCount-2] bb:cpBBNew(SCALE - THICKNESS/2.0,  THICKNESS/2.0, SCALE + THICKNESS/2.0,  SCALE/2.0)]];
  gripperShape.friction = 1.0;
  
  gripperShape = [_space add:[ChipmunkPolyShape boxWithBody:[scissorBodyMArray objectAtIndex:maxCount-1] bb:cpBBNew(SCALE - THICKNESS/2.0, -SCALE/2.0, SCALE + THICKNESS/2.0, -THICKNESS/2.0)]];
  gripperShape.friction = 1.0;
   
  // Add a box for grabbing
  {
  cpFloat size = SCALE - THICKNESS;
  cpFloat mass = 4.0f;
  
  ChipmunkBody *body = [_space add:[ChipmunkBody bodyWithMass:mass andMoment:cpMomentForBox(mass, size, size)]];
  body.pos = cpv(winSize.width-200, 0);
  
  ChipmunkShape *shape = [_space add:[ChipmunkPolyShape boxWithBody:body width:size height:size]];
  shape.elasticity = 0.0f;
  shape.friction = 0.9f;
	}
   */
}


#pragma mark -
#pragma mark Update

-(void)update:(ccTime)dt {
  [_space step:dt];
}

#pragma mark -
#pragma mark Touch Event

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
  for(UITouch *touch in touches){
    CGPoint point = [touch locationInView:[touch view]];
    point = [[CCDirector sharedDirector]convertToGL:point];
    [_multiGrab beginLocation:point];
  }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
  for(UITouch *touch in touches){
    CGPoint point = [touch locationInView:[touch view]];
    point = [[CCDirector sharedDirector]convertToGL:point];
    [_multiGrab updateLocation:point];
  }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for(UITouch *touch in touches){
    CGPoint point = [touch locationInView:[touch view]];
    point = [[CCDirector sharedDirector]convertToGL:point];
    [_multiGrab endLocation:point];
  }
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
  [self ccTouchEnded:touch withEvent:event];
}

#pragma mark -
#pragma mark ChipmunkMultiGrab

-(void)setMultiGrab {
  cpFloat grabForce = 1e5;
  cpFloat smoothing = cpfpow(0.3,60);
  
  _multiGrab = [[ChipmunkMultiGrab alloc]initForSpace:_space withSmoothing:smoothing withGrabForce:grabForce];
  _multiGrab.layers = GRABABLE_MASK_BIT;
  _multiGrab.grabFriction = grabForce*0.1;
  _multiGrab.grabRotaryFriction = 1e3;
  _multiGrab.grabRadius = 20.0;
  _multiGrab.pushMass = 1.0;
  _multiGrab.pushFriction = 0.7;
  _multiGrab.pushMode = FALSE;
}

#pragma mark -
#pragma mark CpDebugLayer

-(void)setDebugLayer {
  _debugLayer = [[CPDebugLayer alloc]initWithSpace:_space.space options:nil];
  [self addChild:_debugLayer z:999];
}

/*
 Target: Use ChipmunkPivotJoint and ChipmunkRotaryLimitJoint to setup a grabber.
 
 1. setup ChipmunkSpace, MultiGrab, DebugLayer and Update as usual.
 2. setup every Chipmunk Body and Shape properly, add Grabber head and tail on it.
 3. setup ChipmunkPivotJoint and ChipmunkRotaryLimitJoint to setup a grabber's ability.
 
 */

#pragma mark -
#pragma mark Init

-(id) init {
	if((self = [super init])) {
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.1],[CCCallBlock actionWithBlock:^(id sender){
      self.isTouchEnabled = YES;
    }], nil]];
    
    [self setSpace];
    
    [self setMultiGrab];
    
    [self setDebugLayer];
    
    [self setObjects];
    
    [self schedule:@selector(update:)];
	}
	return self;
}

- (void) dealloc {
  [_space release];
  [_multiGrab release];
  [_debugLayer release];
  
	[super dealloc];
}

@end
