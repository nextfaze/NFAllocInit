// UIImage (NFAllocInit_Paths)

#import <objc/runtime.h>
#import "UIImage+NFAllocInit_Paths.h"

#define DEFAULT_EXTENSION @"png"
#define IMAGE_EXTENSION(imageName) ([imageName pathExtension].length ? [imageName pathExtension] : DEFAULT_EXTENSION)

@interface NSBundle ()
- (NSString *)nextfazePathForResource:(NSString *)name ofType:(NSString *)ext;
@end

@implementation UIImage (NFAllocInit_Paths)

static BOOL isRetina = NO;

+ (void) load {
    Method m1 = class_getInstanceMethod(NSClassFromString(@"UIImageNibPlaceholder"), @selector(initWithCoder:));
    Method m2 = class_getInstanceMethod(self, @selector(nextfazeInitWithCoder:));
    method_exchangeImplementations(m1, m2);
    
    Method m3 = class_getClassMethod(self, @selector(imageNamed:));
    Method m4 = class_getClassMethod(self, @selector(nextfazeImageNamed:));
    method_exchangeImplementations(m3, m4);
    
    isRetina = ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES && [[UIScreen mainScreen] scale] == 2.00);
    NFLog(@"isRetina: %@", isRetina ? @"YES" : @"NO");
}

- (id)nextfazeInitWithCoder:(NSCoder *)aDecoder {
	NSString *resourceName = [aDecoder decodeObjectForKey:@"UIResourceName"];
	NSString *extension = IMAGE_EXTENSION(resourceName);
	NSString *name = [resourceName stringByDeletingPathExtension];
	
    NSString *newName = [[self class] suffixedNameForImageNamed:name orientation:UIInterfaceOrientationPortrait];
    
	if (newName)
		return [self initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:newName ofType:extension]];
	else
		return [self nextfazeInitWithCoder:aDecoder];
}

+ (UIImage *)imageNamed:(NSString *)imageName orientation:(UIInterfaceOrientation)orientation {
    NSString *extension = IMAGE_EXTENSION(imageName);
    NSString *newName = [self suffixedNameForImageNamed:imageName orientation:orientation];

    NFLog(@"imageNamed: %@ -> %@", imageName, newName);
    
    // if an image with a suffix was found, return it
    if(newName)
        return [self nextfazeImageNamed:[newName stringByAppendingPathExtension:extension]];

    // an image with a suffix was not found, call original implementation method
    return [self nextfazeImageNamed:imageName];
}

+ (UIImage *)nextfazeImageNamed:(NSString *)imageName {
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    return [self imageNamed:imageName orientation:orientation];
}

+ (NSString *)suffixedNameForImageNamed:(NSString *)imageName orientation:(UIInterfaceOrientation)orientation {
    NSString *extension = IMAGE_EXTENSION(imageName);
    NSString *name = [imageName stringByDeletingPathExtension];
    
    // remove any @2x component of image name
    if([name hasSuffix:@"@2x"])
        name = [name substringToIndex:name.length - 3];
    
    // get the list of suffixes to search
    NSArray *searchSuffix = [self suffixSearchPathOrientation:orientation];
    for(NSString *suffix in searchSuffix) {
        // test for an existing file with this suffix
        NSString *name2 = [NSString stringWithFormat:@"%@%@", name, suffix];
        //NFLog(@"looking for resource: %@ ofType: %@", name2, extension);
        NSString *path = [[NSBundle mainBundle] pathForResource:name2 ofType:extension];
        // image found with this suffix, return new name
        if(path) {
            return name2;
        }
    }
    return nil;
}

// return the search path for the given image name
// <basename><orientation_modifier><scale_modifier><device_modifier>.png
+ (NSArray *)suffixSearchPathOrientation:(UIInterfaceOrientation)orientation {
    NSMutableArray *list = [NSMutableArray array];
    NSString *orientationModifier = UIInterfaceOrientationIsPortrait(orientation) ? @"-Portrait" : @"-Landscape";
    NSString *orientationModifier2 = orientation == UIInterfaceOrientationPortraitUpsideDown ? @"-PortraintUpsideDown" : @"SKIP";
    NSString *deviceModifier = [NFDeviceUtils isPad] ? @"~ipad" : @"~iphone";
    NSString *deviceModifier2 = [NFDeviceUtils is4inch] ? @"~568h" : @"SKIP";
    NSArray *scaleModifiers = [self retinaScaleModifiers];
        
    for(NSString *orientMod in @[orientationModifier2, orientationModifier, @""]) {
        if([orientMod isEqualToString:@"SKIP"]) continue;

        for(NSString *scaleMod in scaleModifiers) {
            for(NSString *devMod in @[deviceModifier2, deviceModifier, @""]) {
                if([devMod isEqualToString:@"SKIP"]) continue;
                
                [self addSearchPaths:list modifiers:@[orientMod, scaleMod, devMod]];
            }
        }
    }
    
    //NFLog(@"suffix search list: %@", list);

    return list;
}

+ (void)addSearchPaths:(NSMutableArray *)list modifiers:(NSArray *)modifiers {
    NSString *path = [modifiers componentsJoinedByString:@""];
    [list addObject:path];
}

+ (NSArray *)retinaScaleModifiers {
    NSMutableArray *list = [NSMutableArray array];
    [list addObject:@"@2x"];
    [list addObject:@""];

    // if on a non-retina device, look for images without a @2x extension first
    return isRetina ? list : [[list reverseObjectEnumerator] allObjects];
}

@end