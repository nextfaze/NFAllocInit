//
//  NFProperty.h
//  NFAllocInit
//
//  Created by Andrew Williams on 20/02/2014.
//  Copyright (c) 2014 NextFaze SD. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum  {
    NFPropertyValueTypeUnknown,
    NFPropertyValueTypeObject,
    NFPropertyValueTypePrimitive
} NFPropertyValueType;

typedef enum {
    NFPropertyDataTypeUnknown,
    NFPropertyDataTypeInt,
    NFPropertyDataTypeUnsignedInt,
    NFPropertyDataTypeLong,
    NFPropertyDataTypeUnsignedLong,
    NFPropertyDataTypeChar,
    NFPropertyDataTypeUnsignedChar,
    NFPropertyDataTypeObject,
} NFPropertyDataType;

@interface NFProperty : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NFPropertyDataType valueType;
@property (nonatomic, readonly) int pointerLevel;

// if valueType == NFPropertyDataTypeObject, this will be set to the class of the value
@property (nonatomic, readonly) Class valueClass;

- (BOOL)isPointer;

+ (NSArray *)propertiesFromClass:(Class)klass;
+ (NSDictionary *)propertiesDictionaryFromClass:(Class)klass;

@end