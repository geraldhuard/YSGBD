//
//  YSGBD.m
//
//  Modified by Gildas A. on 16/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "YSGBD.h"
#import "NSFileManager+Yooneo.h"

static YSGBD *sharedCurrent=NULL;

@implementation YSGBD

@synthesize sgbd;

#pragma marl static functions
+(YSGBD*) shared{
    if (sharedCurrent == NULL) {
        sharedCurrent = [[YSGBD alloc] initWithDBFileName:@"your_sgdb_name_here"];
    }
    return sharedCurrent;
}

+(void) sClose{
    [[YSGBD shared] close];
}

+(void) sOpen{
    [[YSGBD shared] open];
}

+(BOOL) sExec:(NSString*)req{
    return [[YSGBD shared] exec:req];
}

+(NSMutableArray*) sExecAndGet:(NSString*)req{
    return [[YSGBD shared] execAndGet:req];
}

+(BOOL) sInsertDict:(NSDictionary*)dict intoTable:(NSString*)table{
    return [[YSGBD shared] insertDict:dict intoTable:table];
}

+(BOOL) sUpdateDict:(NSDictionary*)dict intoTable:(NSString*)table withKeysNames:(NSArray*)keys{
    return [[YSGBD shared] updateDict:dict intoTable:table withKeysNames:keys];
}

+(BOOL) sPutWithDict:(NSDictionary*)dict intoTable:(NSString*)table andKeysNames:(NSArray*)keys{
    return [[YSGBD shared] putWithDict:dict intoTable:table andKeysNames:keys];
}

+(BOOL) sRemoveWithDict:(NSDictionary*)dict intoTable:(NSString*)table andKeysNames:(NSArray*)keys{
    return [[YSGBD shared] removeWithDict:dict fromTable:table andKeysNames:keys];
}

+(BOOL) sEmptyTable:(NSString *)tableName{
    return [[YSGBD shared] emptyTable:tableName];
}


#pragma mark instance functions
-(id) initWithDBFileName:(NSString*)_dbfilename{
    if (self=[super init]){
        dbfilename=_dbfilename;
        sgbd_opened=NO;
        sharedCurrent=self;
    }
    
    return self;
}

-(void) open{
    
    if (sgbd_opened && [sgbd_openedpath isEqualToString:dbpathname])return;
    else{
        [self setEditableDatabaseIfNeeded];
        
        const char *path = [dbpathname UTF8String];
        
        
        
        if (sqlite3_open_v2(path, &sgbd, SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, "unix-none") == SQLITE_OK){
            sqlite3_config(SQLITE_CONFIG_MULTITHREAD);
            //if (sqlite3_open(path, &sgbd) == SQLITE_OK){
            sgbd_opened=YES;
            sgbd_openedpath=dbpathname;
    		
            //Making every stuff with the database transactional.
            [self beginTransaction];
            NSLog(@"[SGBD][Error] [%@] opened...",dbpathname);
        }
        else{
            
            NSLog(@"[SGBD][Error] [%@] opening error...",dbpathname);
            [self logerr];
        }
    }
}

- (void) beginTransaction{
    sqlite3_exec(sgbd, "BEGIN", 0, 0, 0);
}

- (void) rollBackTransaction{
    sqlite3_exec(sgbd, "ROLLBACK", 0, 0, 0);
}

- (void) commitTransaction{
    sqlite3_exec(sgbd, "COMMIT", 0, 0, 0);
}

- (void)setEditableDatabaseIfNeeded {
    BOOL success;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *documentsDirectory = [NSFileManager getDocumentDirectory];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:dbfilename];
    success = [fileManager fileExistsAtPath:writableDBPath];
    
    dbpathname=writableDBPath;
    
    if (success){
        NSLog(@"[SGBD][Infos] dbpath -> %@",writableDBPath);
        return;
    }   
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:dbfilename];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    NSLog(@"[SGBD][Infos] Copy SGBD [%@] to [%@]",defaultDBPath,writableDBPath);
    if (!success) {
        NSLog(@"[SGBD][Error] Failed to create writable database file [%@] from [%@] with message '%@'.",writableDBPath,defaultDBPath, [error localizedDescription]);
    }
}

-(void) close{
    if (sgbd_opened){
        [self commitTransaction];
        sqlite3_close(sgbd);
        //NSLog(@"[SGBD][Infos] [%@] closed...",dbpathname);
    }
    sgbd_opened=NO;
    sgbd_openedpath=@"";
}

-(BOOL) insertDict:(NSDictionary*)dict intoTable:(NSString*)table{
    if (!sgbd_opened)return NO;
    
    
    NSMutableString *req=[NSMutableString stringWithFormat:@"INSERT INTO %@(",table];
    NSEnumerator *enumerator = [dict keyEnumerator];
    NSString *key;
    
    while ((key = [enumerator nextObject]))[req appendFormat:@"\"%@\",",key];
    
    req = [NSMutableString stringWithString:[req substringToIndex:[req length] - 1]];
    [req appendFormat:@") VALUES ("];
    
    enumerator = [dict keyEnumerator];
    
    while ((key = [enumerator nextObject])){
        NSObject *value = [dict objectForKey:key];
        
        //Permet d'echapper les simples quote lors de l'insertion.
        if ([value isKindOfClass:[NSString class]]) {
            value = [(NSString*)value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        }
        [req appendFormat:@"'%@',",value];
    }
    req = [NSMutableString stringWithString:[req substringToIndex:[req length] - 1]];
    [req appendFormat:@");"];
    
    return [self exec:req];
}

-(BOOL) replaceDict:(NSDictionary*)dict intoTable:(NSString*)table{
    if (!sgbd_opened)return NO;
    
    
    NSMutableString *req=[NSMutableString stringWithFormat:@"REPLACE INTO %@(",table];
    NSEnumerator *enumerator = [dict keyEnumerator];
    NSString *key;
    
    while ((key = [enumerator nextObject]))[req appendFormat:@"\"%@\",",key];
    
    req = [NSMutableString stringWithString:[req substringToIndex:[req length] - 1]];
    [req appendFormat:@") VALUES ("];
    
    enumerator = [dict keyEnumerator];
    while ((key = [enumerator nextObject]))[req appendFormat:@"\"%@\",",[dict objectForKey:key]];
    req = [NSMutableString stringWithString:[req substringToIndex:[req length] - 1]];
    [req appendFormat:@");"];
    
    return [self exec:req];
}

-(BOOL) rowExistWithDict:(NSDictionary*)dict table:(NSString*)table andKeysNames:(NSArray*)keys{
    NSString *req=[NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE 1=1 ",[keys componentsJoinedByString:@","],table];
    
    NSMutableString *where=[NSMutableString stringWithFormat:@""];
    for (int i=0;i<[keys count];i++){
        NSString *key=[keys objectAtIndex:i];
        NSObject *value = [dict objectForKey:key];
        
        //Permet d'echapper les simples quote lors de l'insertion.
        if ([value isKindOfClass:[NSString class]]) {
            value = [(NSString*)value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        }
        [where appendFormat:@"AND %@='%@' ",key,value]; 
    }
    NSString *reqWithWhere=[req stringByAppendingString:where];
    
    NSArray *reps=[self execAndGet:reqWithWhere];
    return ([reps count]>0);
}

-(BOOL) updateDict:(NSDictionary*)dict intoTable:(NSString*)table withKeysNames:(NSArray*)keys{
    NSMutableString *req=[NSMutableString stringWithFormat:@"UPDATE %@ SET ",table];
    
    NSEnumerator *enumerator = [dict keyEnumerator];
    NSString *key;
    while ((key = [enumerator nextObject])){
        NSObject *value = [dict objectForKey:key];
        
        //Permet d'echapper les simples quote lors de l'insertion.
        if ([value isKindOfClass:[NSString class]]) {
            value = [(NSString*)value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        }
        [req appendFormat:@"%@='%@', ",key,value];
    }
    NSString *ssreq=[req substringToIndex:[req length]-2];
    req=[NSMutableString stringWithFormat:@"%@ WHERE 1=1 ",ssreq];
    
    for (int i=0;i<[keys count];i++){
        key=[keys objectAtIndex:i];
        NSObject *value2 = [dict objectForKey:key];
        
        //Permet d'echapper les simples quote lors de l'insertion.
        if ([value2 isKindOfClass:[NSString class]]) {
            value2 = [(NSString*)value2 stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        }
        [req appendFormat:@"AND %@='%@' ",key,value2]; 
    }
    return ([self exec:req]);
}

-(BOOL) putWithDict:(NSDictionary*)dict intoTable:(NSString*)table andKeysNames:(NSArray*)keys{
    if ([self rowExistWithDict:dict table:table andKeysNames:keys])
        return [self updateDict:dict intoTable:table withKeysNames:keys];
    else
        return [self insertDict:dict intoTable:table];
}

-(BOOL) removeWithDict:(NSDictionary*)dict fromTable:(NSString*)table andKeysNames:(NSArray*)keys{
    if ([self rowExistWithDict:dict table:table andKeysNames:keys]){
        NSString *ssreq=[NSString stringWithFormat:@"DELETE FROM %@ ",table];
        NSMutableString *req=[NSMutableString stringWithFormat:@"%@ WHERE 1=1 ",ssreq];
        
        for (int i=0;i<[keys count];i++){
            NSString *key=[keys objectAtIndex:i];
            NSObject *value = [dict objectForKey:key];
            
            //Permet d'echapper les simples quote lors de l'insertion.
            if ([value isKindOfClass:[NSString class]]) {
                value = [(NSString*)value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
            }
            [req appendFormat:@"AND %@='%@' ",key,value]; 
        }
        return ([self exec:req]);
    }
    return NO;
}

-(void) logerr{
    int   code=sqlite3_errcode(sgbd);
    NSString *msgErr=[NSString stringWithUTF8String:sqlite3_errmsg( sgbd )];
    
    NSLog(@"[SGBD][Error] [%d] => %@",code,msgErr);
    
}

-(BOOL) exec:(NSString*)req{
    if (!sgbd_opened)return NO;
    
    
    sqlite3_stmt    *stmt;
    const char *query = [req UTF8String];
    BOOL ok=NO;
    if (sqlite3_prepare_v2(sgbd, query, strlen(query), &stmt, NULL) == SQLITE_OK)
        if (stmt!=NULL)ok= (sqlite3_step(stmt) == SQLITE_DONE);
    
    if (!ok){
        NSLog(@"[SGBD][Error] REQ[%@]",req);
        [self logerr];  
    }
    sqlite3_finalize(stmt);    
    return ok;
}

-(NSMutableArray*) execAndGet:(NSString*)req{
    if (!sgbd_opened)return nil;
    
    sqlite3_stmt    *stmt=NULL;
    const char *query = [req UTF8String];
    
    NSMutableArray *out=[[NSMutableArray alloc] init];
    //NSLog(@"[SGBD][Error] execAndGet(%@)",req);
    if (sqlite3_prepare_v2(sgbd, query, strlen(query), &stmt, NULL) == SQLITE_OK){
        while (stmt!=NULL && (sqlite3_step(stmt) == SQLITE_ROW)){
            
            int nbcol=sqlite3_column_count(stmt);
            
            NSMutableDictionary *dict=[[NSMutableDictionary alloc] init];
            
            
            for (int i=0;i<nbcol;i++){
                if (stmt!=NULL){
                    int type=sqlite3_column_type(stmt, i);
                    NSString *colname=[NSString stringWithUTF8String:sqlite3_column_name(stmt, i)];
                    
                    int valInt;
                    double valF;
                    const unsigned char *text;
                    
                    switch (type) {
                        case SQLITE_INTEGER:                        
                            valInt=sqlite3_column_int(stmt, i);
                            if (&valInt!=NULL){
                                NSNumber *numI=[[NSNumber alloc] initWithInt:valInt];
                                [dict setValue:numI forKey:colname];
                            }
                            break;
                        case SQLITE_FLOAT:                        
                            valF=sqlite3_column_double(stmt, i);
                            if (&valF!=NULL){
                                NSNumber *numF=[[NSNumber alloc] initWithFloat:valF];
                                [dict setValue:numF forKey:colname];
                            }
                            break;
                        case SQLITE_TEXT:        
                            valInt=0;
                            text=sqlite3_column_text(stmt, i);
                            if (text!=NULL){
                                NSString *str=[NSString stringWithUTF8String:(const char*)text];
                                [dict setValue:str forKey:colname];
                            } 
                            break;
                        default:
                            break;
                    }
                }
            }
            [out addObject:dict]; 
        }            
        if (stmt!=NULL)sqlite3_finalize(stmt);
    }else{
        [self logerr];
    }
    return out;
}

-(BOOL) emptyTable:(NSString*)tablename{
    NSString *req=[NSString stringWithFormat:@"DELETE FROM %@;",tablename];
    return [self exec:req];
}

- (long) lastRowID{
    return sqlite3_last_insert_rowid(sgbd);
}

@end