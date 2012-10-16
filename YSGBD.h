//
//  YSGBD.h
//
//  Modified by Gildas A. on 16/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@interface YSGBD : NSObject{
    NSString        *dbpathname;
    NSString        *dbfilename;
    BOOL            sgbd_opened;
    NSString        *sgbd_openedpath;
    sqlite3         *sgbd;
}

@property (nonatomic) sqlite3 *sgbd;

+(id)       shared;
+(void)     sClose;
+(BOOL)     sExec:(NSString*)req;
+(NSMutableArray*) sExecAndGet:(NSString*)req;
+(BOOL)     sInsertDict:(NSDictionary*)dict intoTable:(NSString*)table;
+(BOOL)     sUpdateDict:(NSDictionary*)dict intoTable:(NSString*)table withKeysNames:(NSArray*)keys;
+(BOOL)     sPutWithDict:(NSDictionary*)dict intoTable:(NSString*)table andKeysNames:(NSArray*)keys;
+(BOOL)     sRemoveWithDict:(NSDictionary*)dict intoTable:(NSString*)table andKeysNames:(NSArray*)keys;
+(BOOL)     sEmptyTable:(NSString*)tableName;

-(BOOL)     rowExistWithDict:(NSDictionary*)dict table:(NSString*)table andKeysNames:(NSArray*)keys;
-(id)       initWithDBFileName:(NSString*)dbfilename;
-(void)     setEditableDatabaseIfNeeded;
-(void)     open;
-(void)     close;
-(BOOL)     exec:(NSString*)req;
-(NSMutableArray*) execAndGet:(NSString*)req;
-(BOOL)     insertDict:(NSDictionary*)dict intoTable:(NSString*)table;
-(BOOL)     replaceDict:(NSDictionary*)dict intoTable:(NSString*)table;
-(BOOL)     putWithDict:(NSDictionary*)dict intoTable:(NSString*)table andKeysNames:(NSArray*)keys;
-(BOOL)     updateDict:(NSDictionary*)dict intoTable:(NSString*)table withKeysNames:(NSArray*)keys;
-(BOOL)     removeWithDict:(NSDictionary*)dict fromTable:(NSString*)table andKeysNames:(NSArray*)keys;


-(BOOL)     emptyTable:(NSString*)tablename;
-(void)     logerr;

@end
