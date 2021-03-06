//
//  CSqliteDatabase_Functions.m
//  TouchCode
//
//  Created by Jonathan Wight on 12/9/08.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import "CSqliteDatabase_Functions.h"

//static void group_concat_step(sqlite3_context *ctx, int ncols, sqlite3_value **values);
//static void group_concat_finalize(sqlite3_context *ctx);
static void word_search_func(sqlite3_context* ctx, int argc, sqlite3_value** argv);

@implementation CSqliteDatabase (CSqliteDatabase_Functions)

- (BOOL)loadFunctions:(NSError **)outError
{
int theResult;

//int theResult = sqlite3_create_function(self.sql, "group_concat", 1, SQLITE_UTF8, self.sql, NULL, group_concat_step, group_concat_finalize);    
//if (theResult != SQLITE_OK)
//	{
//	if (outError)
//		*outError = [self currentError];
//	return(NO);
//	}
//

theResult = sqlite3_create_function(self.sql, "word_search", 2, SQLITE_UTF8, NULL, word_search_func, NULL, NULL);
if (theResult != SQLITE_OK)
	{
	if (outError)
		*outError = [self currentError];
	return(NO);
	}
return(YES);
}

// sqlite group_concat functionality

//typedef struct {
//    NSMutableArray *values;
//} group_concat_ctxt;
//
//static void group_concat_step(sqlite3_context *ctx, int ncols, sqlite3_value **values)
//{
//    group_concat_ctxt *g;
//    const unsigned char *bytes;
//    
//    g = (group_concat_ctxt *)sqlite3_aggregate_context(ctx, sizeof(group_concat_ctxt));
//    
//    if (sqlite3_aggregate_count(ctx) == 1)
//    {
//        g->values = [[NSMutableArray alloc] init];
//    }
//    
//    bytes = sqlite3_value_text(values[0]); 
//    [g->values addObject:[NSString stringWithCString:(const char *)bytes encoding:NSUTF8StringEncoding]];
//}
//
//static void group_concat_finalize(sqlite3_context *ctx)
//{
//    group_concat_ctxt *g;
//    
//    g = (group_concat_ctxt *)sqlite3_aggregate_context(ctx, sizeof(group_concat_ctxt));
//    const char *finalString = [[g->values componentsJoinedByString:@", "] UTF8String];
//    sqlite3_result_text(ctx, finalString, strlen(finalString), NULL);
//    [g->values release];
//    g->values = nil;
//}

// sqlite word search function
static void word_search_func(sqlite3_context* ctx, int argc, sqlite3_value** argv)
{    
    int wasFound = 0;
    static NSCharacterSet *charSet = nil;
    
    if (!charSet)
    {
        charSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
    }
    
    const unsigned char *s2 = sqlite3_value_text(argv[1]);
    NSString *string2 = [[NSString alloc] initWithUTF8String:(const char *)s2];
    
    // Borrow the buffer here
    const unsigned char *s1 = sqlite3_value_text(argv[0]);
    NSString *string1 = [[NSString alloc] initWithBytesNoCopy:(void *)s1 length:(NSInteger)sqlite3_value_bytes(argv[0]) encoding:NSUTF8StringEncoding freeWhenDone:NO];
    
    // Prepare to be searched!
    NSInteger curLoc = 0;
    NSInteger maxLoc = [string1 length];
    
    NSUInteger string2Len = [string2 length];
    while (curLoc < maxLoc)
    {
        NSRange searchRange = NSMakeRange(curLoc, maxLoc - curLoc);
        if (searchRange.length < string2Len)
        {
            break;
        }
        
        NSComparisonResult res = [string1 compare:string2 options:NSDiacriticInsensitiveSearch|NSCaseInsensitiveSearch range:NSMakeRange(curLoc, string2Len)];
        
        if (res == 0)
        {
            wasFound = 1;
            break;
        }
        
        // find the next whitespace to start from
        NSRange wsRange = [string1 rangeOfCharacterFromSet:charSet options:NSLiteralSearch range:searchRange];
        if (wsRange.location == NSNotFound)
        {
            break;
        }
        curLoc = wsRange.location + 1;
    }
    
    sqlite3_result_int(ctx, wasFound);
}



@end
