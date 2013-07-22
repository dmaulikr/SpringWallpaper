//
//  MFStringRenderer.m
//
//  Created by Chance Hudson on 5/14/13.
//  Copyright (c) 2013 Chance Hudson. All rights reserved.
//

#import "MFStringRenderer.h"
#import "MFBatchRenderer.h"

@implementation MFStringRenderer

-(id)init{
    if((self = [super init])){
        characterSetArray = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CharacterSets" ofType:@"plist"]] objectForKey:@"characterSets"];
        [characterSetArray retain];
        characterLists = malloc(sizeof(MFGLCharacterSet)*BASE_CHARACTER_SET_COUNT);
        characterListSize = BASE_CHARACTER_SET_COUNT;
        strings = malloc(sizeof(MFGLString)*BASE_STRING_COUNT);
        stringsArraySize = BASE_STRING_COUNT;
    }
    return self;
}

-(void)loadCharacterSetsForAtlas:(GLuint)atlas atlasDict:(NSMutableDictionary*)atlasDict atlasSize:(CGSize)atlasSize atlasScale:(float)atlasScale{
    for(int x = 0; x < characterSetArray.count; x++){
        NSDictionary *setDict = [characterSetArray objectAtIndex:x];
        NSString *characters = [setDict objectForKey:@"characters"];
        NSString *prefix = [[characterSetArray objectAtIndex:x] objectForKey:@"prefix"];
        NSString *name = [prefix stringByAppendingString:[characters substringWithRange:(NSRange){0,1}]];
        NSMutableDictionary *imageDict = [[atlasDict objectForKey:@"frames"] objectForKey:name];
        NSString *s = [imageDict objectForKey:@"textureRect"];
        
        if(!s) continue;
        
        MFGLCharacterSet set;
        set.images = malloc(sizeof(MFGLImage)*characters.length);
        for(int y = 0; y < characters.length; y++){
            NSString *cName = [prefix stringByAppendingString:[characters substringWithRange:(NSRange){y,1}]];
            set.images[y] = MFGLImageCreateUsingAtlas(atlas, cName, atlasDict, atlasScale, atlasSize);
        }
        set.characters = characters;
        set.imageCount = (int)characters.length;
        set.listID = [[setDict objectForKey:@"listID"] intValue];
        set.prefix = prefix;
        
        if(characterListCount+1 >= characterListSize){ //check if need to make the character list array longer
            characterListSize += BASE_CHARACTER_SET_COUNT;
            characterLists = realloc(characterLists, sizeof(MFGLCharacterSet)*characterListSize);
        }
        characterLists[characterListCount] = set;
        characterListCount++;
    }
}

-(int)addString:(NSString*)string characterListPrefix:(NSString*)prefix origin:(CGPoint)origin alpha:(float)alpha  alphaFadeRate:(float)alphaFadeRate velocity:(CGSize)velocity lifetime:(float)lifetime drawOffset:(BOOL)drawOffset{
    int listID = -1;
    int listIndex = -1;
    for(int x = 0; x < characterListCount; x++){
        if([characterLists[x].prefix isEqualToString:prefix]){
            listID = characterLists[x].listID;
            listIndex = x;
        }
    }
    if(listID == -1){
        NSLog(@"No character list for prefix: %@", prefix);
        return -1;
    }
    if(stringsArrayCount+1 >= stringsArraySize){ //check if need to make the string array longer
        stringsArraySize += BASE_CHARACTER_ARRAY_COUNT;
        strings = realloc(strings, sizeof(MFGLString)*stringsArraySize);
        NSLog(@"Making string array larger");
    }
    MFGLString finalString;
    finalString.string = [string retain];
    finalString.characterListID = listID;
    finalString.imageIndexes = malloc(sizeof(int)*string.length);
    finalString.active = YES;
    finalString.alpha = alpha;
    finalString.lifetime = lifetime;
    finalString.characterListIndex = listIndex;
    finalString.currentLifetime = 0;
    finalString.drawOffset = drawOffset;
    finalString.origin = origin;
    finalString.alphaFadeRate = alphaFadeRate;
    finalString.xVel = velocity.width;
    finalString.yVel = velocity.height;
    for(int x = 0; x < string.length; x++){
        NSRange r = [characterLists[listIndex].characters rangeOfString:[string substringWithRange:(NSRange){x,1}]];
        if(r.location != NSNotFound){
            //character set has the character needed
            finalString.imageIndexes[x] = (int)r.location;
        }
        if([[string substringWithRange:(NSRange){x,1}] isEqualToString:@" "]){
            finalString.imageIndexes[x] = -1;
        }
    }
    for(int x = 0; x < stringsArraySize; x++){
        if(strings[x].active != YES){
            strings[x] = finalString;
            strings[x].tag = x;
            stringsArrayCount++;
            return x;
        }
    }
    return -1;
}

-(void)replaceStringWithTag:(int)tag withString:(NSString*)newString{
    MFGLString currentString;
    int stringIndex = -1;
    for(int x = 0; x < stringsArraySize; x++){
        if(strings[x].tag == tag){
            currentString = strings[x];
            stringIndex = x;
        }
    }
    if(stringIndex == -1) return; //no string with that tag exists
    if(currentString.active){
        currentString = [self destroyString:currentString];
        strings[stringIndex] = currentString;
    }
    else
        stringsArrayCount++;
    currentString.string = [newString retain];
    currentString.currentLifetime = 0;
    currentString.imageIndexes = malloc(sizeof(int)*newString.length);
    for(int x = 0; x < newString.length; x++){
        NSRange r = [characterLists[currentString.characterListIndex].characters rangeOfString:[newString substringWithRange:(NSRange){x,1}]];
        if(r.location != NSNotFound){
            //character set has the character needed
            currentString.imageIndexes[x] = (int)r.location;
        }
        if([[newString substringWithRange:(NSRange){x,1}] isEqualToString:@" "]){
            currentString.imageIndexes[x] = -1;
        }
    }
    currentString.active = YES;
    strings[stringIndex] = currentString;
}

-(void)removeStringWithTag:(int)tag{
    MFGLString currentString;
    int stringIndex = -1;
    for(int x = 0; x < stringsArraySize; x++){
        if(strings[x].tag == tag){
            currentString = strings[x];
            stringIndex = x;
        }
    }
    if(stringIndex == -1) return; //no string with that tag exists
    if(currentString.active){
        currentString = [self destroyString:currentString];
        strings[stringIndex] = currentString;
    }
    stringsArrayCount--;
}

-(void)drawStringsWithBatchRenderer:(MFBatchRenderer*)batchRenderer offset:(MFVector)offset frametime:(float)frameTime{
    for(int x = 0; x < stringsArraySize; x++){
        MFGLString string = strings[x];
        if(string.active != YES) continue;
        if(string.lifetime != -1){
            string.currentLifetime += frameTime;
            if(string.currentLifetime > string.lifetime){
                strings[x] = [self destroyString:string];
                stringsArrayCount--;
                continue;
            }
            strings[x] = string;
        }
        string.alpha += string.alphaFadeRate*frameTime;
        if(string.alpha > 1)
            string.alpha = 1;
        if(string.alpha < 0){
            strings[x] = [self destroyString:string];
            stringsArrayCount--;
            continue;
        }
        string.origin.x += string.xVel*frameTime;
        string.origin.y += string.yVel*frameTime;
        strings[x] = string;
        CGPoint currentPoint = string.origin;
        for(int z = 0; z < string.string.length; z++){
            if(string.imageIndexes[z] == -1){
                //it's a space
                currentPoint.x += characterLists[string.characterListIndex].images[0].size.width;
                continue;
            }
            MFGLImage currentImage = characterLists[string.characterListIndex].images[string.imageIndexes[z]];
            [batchRenderer addFrame:(CGRect){CGPointMake(currentPoint.x, currentPoint.y-currentImage.size.height), currentImage.size} withAlpha:string.alpha forImage:currentImage renderAlpha:YES offset:string.drawOffset?offset:CGPointZero];
            currentPoint.x += currentImage.size.width;
        }
    }
}

-(MFGLString)destroyString:(MFGLString)string{
    string.active = NO;
    free(string.imageIndexes);
    [string.string release];
    string.string = nil;
    return string;
}

-(void)dealloc{
    //destroy all the character sets
    characterListCount = 0;
    for(int x = 0; x < characterListCount; x++){
        free(characterLists[x].images);
    }
    free(characterLists);
    //destroy any left over strings
    stringsArrayCount = 0;
    free(strings);
    [characterSetArray release];
    characterSetArray = nil;
    [super dealloc];
}

@end
