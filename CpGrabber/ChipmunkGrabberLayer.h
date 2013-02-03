//
//  ChipmunkGrabberLayer.h
//  BasicCocos2D
//
//  Created by Ian Fan on 27/08/12.
//
//

#import "cocos2d.h"
#import "ObjectiveChipmunk.h"
#import "CPDebugLayer.h"

@interface ChipmunkGrabberLayer : CCLayer
{
  ChipmunkSpace *_space;
  ChipmunkMultiGrab *_multiGrab;
  CPDebugLayer *_debugLayer;
}

+(CCScene *) scene;

@end
