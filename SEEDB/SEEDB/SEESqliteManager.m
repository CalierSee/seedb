//
//  SEESqliteManager.m
//  qztourist
//
//  Created by 景彦铭 on 2016/11/20.
//  Copyright © 2016年 景彦铭. All rights reserved.
//

#import "SEESqliteManager.h"
#import <sqlite3.h>
#import <objc/runtime.h>

@interface SEESqliteManager ()
{
    sqlite3 * _sql;
}
@end

@implementation SEESqliteManager

+ (instancetype)shareManager {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self createSqlite];
    }
    return nil;
}

- (int)createSqlite {
    return sqlite3_open([self sqlitePath], &_sql);
}

- (int)insertDatas:(id)datas toTable:(NSString *)table {
    if([datas isKindOfClass:[NSArray class]]){
        sqlite3_exec(_sql, @"BEGIN TRANSACTION;".UTF8String, NULL, NULL, NULL);
        @try {
            for (id data in (NSArray *)datas) {
                [self insertData:data toTable:table];
            }
        } @catch (NSException *exception) {
            sqlite3_exec(_sql, @"ROLLBACK TRANSACTION;".UTF8String, NULL, NULL, NULL);
            return 0;
        } @finally {
            sqlite3_exec(_sql, @"COMMIT TRANSACTION;".UTF8String, NULL, NULL, NULL);
            return 1;
        }
    }
    else {
        return ![self insertData:datas toTable:table];
    }
}

- (int)insertData:(id)data toTable:(NSString *)table {
    NSDictionary * dict = [self dictionaryWithObjc:data];
    if(![self createTable:table withDictionary:dict]){
        return 1;
    }
    __block NSMutableString * sayOne = [NSMutableString stringWithFormat:@"insert into '%@'(",table];
    __block NSMutableString * sayTwo = [NSMutableString stringWithFormat:@") values("];
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [sayOne appendFormat:@"%@,",key];
        [sayTwo appendFormat:@"'%@',",obj];
    }];
    NSRange range;
    range.location = sayOne.length - 1;
    range.length = 1;
    [sayOne deleteCharactersInRange:range];
    range.location = sayTwo.length - 1;
    [sayTwo deleteCharactersInRange:range];
    [sayOne appendString:sayTwo];
    [sayOne appendString:@");"];
    return sqlite3_exec(_sql, sayOne.UTF8String, NULL, NULL, NULL);
}

- (int)createTable:(NSString *)table withDictionary:(NSDictionary *)dict {
    __block NSMutableString * say = [NSMutableString stringWithFormat:@"create table if not exists '%@'(",table];
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [say appendFormat:@"%@ text,",key];
    }];
    NSRange range;
    range.location = say.length - 1;
    range.length = 1;
    [say deleteCharactersInRange:range];
    [say appendString:@");"];
    return sqlite3_exec(_sql, say.UTF8String, NULL, NULL, NULL);
}

- (nullable NSArray *)objectForClass:(nonnull Class)cla fromTable:(nonnull NSString *)table where:(NSString * _Nullable)where completeBlock:(nullable void (^)())complete{
    //拼接sql语句
    NSMutableString * say = [NSMutableString string];
    NSMutableString * whereStr = [NSMutableString string];
    if(where){
        [whereStr appendString:[NSString stringWithFormat:@"select * from '%@' where %@;",table,where]];
    }
    else {
        [whereStr appendString:[NSString stringWithFormat:@"select * from '%@';",table]];
    }
    [say appendString:whereStr];
    //创建对象数组接收对象
    NSArray * dictArr = [self dictionaryFromSql:say.copy];
    if (dictArr.count == 0) {
        return nil;
    }
    NSMutableArray * objcArr = [NSMutableArray array];
    [dictArr enumerateObjectsUsingBlock:^(NSDictionary * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id objc = [[cla alloc]init];
        [objc setValuesForKeysWithDictionary:obj];
        [objcArr addObject:objc];
    }];
    if(complete != nil){
        dispatch_async(dispatch_get_main_queue(), ^{
            complete();
        });
    }
    return objcArr.copy;
}

- (NSArray <NSDictionary *> *)dictionaryFromSql:(NSString * _Nullable)sql {
    NSMutableArray * dictArr = [NSMutableArray array];
    //预编译
    sqlite3_stmt *ppStmt;
    if(sqlite3_prepare_v2(_sql, sql.UTF8String, -1, &ppStmt, NULL) == SQLITE_OK) {
        while(sqlite3_step(ppStmt) == SQLITE_ROW){
            //取结果集
            NSMutableDictionary * objc = [NSMutableDictionary dictionary];
            for (int i  = 0; i < sqlite3_column_count(ppStmt); i++) {
                NSString * key = [NSString stringWithUTF8String:sqlite3_column_name(ppStmt, i)];
                const char * valueC = (const char *)sqlite3_column_text(ppStmt, i);
                id value;
                if(valueC){
                    value = [NSString stringWithUTF8String:valueC];
                }
                else {
                    value = @"";
                }
                [objc setValue:value forKey:key];
            }
            [dictArr addObject:objc];
        }
    }
    sqlite3_finalize(ppStmt);
    return dictArr;
}

- (int)deleteDatas:(nonnull id)datas forTable:(nonnull NSString *)table forIdField:(nonnull NSString *)idField{
    if([datas isKindOfClass:[NSArray class]]){
        sqlite3_exec(_sql, @"BEGIN TRANSACTION;".UTF8String, NULL, NULL, NULL);
        @try {
            for (id data in (NSArray *)datas) {
                [self deleteData:data forTable:table forIdField:idField];
            }
        } @catch (NSException *exception) {
            sqlite3_exec(_sql, @"ROLLBACK TRANSACTION;".UTF8String, NULL, NULL, NULL);
            return 0;
        } @finally {
            sqlite3_exec(_sql, @"COMMIT TRANSACTION;".UTF8String, NULL, NULL, NULL);
            return 1;
        }
    }
    else {
        return ![self deleteData:datas forTable:table forIdField:idField];
    }
}

- (int)deleteData:(id)data forTable:(NSString *)table forIdField:(NSString *)field {
    NSString * say = [NSString stringWithFormat:@"delete from '%@' where %@='%@'",table,field,[data valueForKey:field]];
    return sqlite3_exec(_sql, say.UTF8String, NULL, NULL, NULL);
}

- (int)updateDatas:(id)datas forTable:(NSString *)table forIdField:(NSString *)idField field:(NSString *)field,...NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray * stringM = [NSMutableArray array];
    if(field){
        va_list args;
        va_start(args, field);
        [stringM addObject:field];
        NSString * otherString;
        while((otherString = va_arg(args, NSString *))){
            [stringM addObject:otherString];
        }
        va_end(args);
    }
    if([datas isKindOfClass:[NSArray class]]){
        sqlite3_exec(_sql, @"BEGIN TRANSACTION;".UTF8String, NULL, NULL, NULL);
        @try {
            for (id data in (NSArray *)datas) {
                [self updateData:data forTable:table forIdField:idField fields:stringM.copy];
            }
        } @catch (NSException *exception) {
            sqlite3_exec(_sql, @"ROLLBACK TRANSACTION;".UTF8String, NULL, NULL, NULL);
            return 0;
        } @finally {
            sqlite3_exec(_sql, @"COMMIT TRANSACTION;".UTF8String, NULL, NULL, NULL);
            return 1;
        }
    }
    else {
        return ![self updateData:datas forTable:table forIdField:idField fields:stringM.copy];
    }
}

- (int)updateData:(id)data forTable:(NSString *)table forIdField:(NSString *)idField fields:(NSArray *)fields{
    //update 'abcd' set name = 'json',age = '13' where id = '1234';
    NSMutableString * say = [NSMutableString stringWithFormat:@"update '%@' set ",table];
    if(fields.count == 0){
        fields = [self arrayWithPropertyNameForClass:[data class]];
    }
    for (NSString * key in fields) {
        if([key isEqualToString:idField]){
            continue;
        }
        [say appendString:[NSString stringWithFormat:@"%@='%@',",key,[data valueForKey:key]]];
    }
    NSRange range;
    range.length = 1;
    range.location = say.length - 1;
    [say deleteCharactersInRange:range];
    [say appendString:[NSString stringWithFormat:@" where %@='%@';",idField,[data valueForKey:idField]]];
    return sqlite3_exec(_sql, say.UTF8String, NULL, NULL, NULL);
}

- (void)updateObjcs:(id)objcs withTable:(NSString *)table idField:(NSString *)idField field:(NSString *)field,...NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray * stringM = [NSMutableArray array];
    if(field){
        va_list args;
        va_start(args, field);
        [stringM addObject:field];
        NSString * otherString;
        while((otherString = va_arg(args, NSString *))){
            [stringM addObject:otherString];
        }
        va_end(args);
    }
    if([objcs isKindOfClass:[NSArray class]]){
        for(id obj in (NSArray *)objcs){
            [self updateObjc:obj withTable:table idField:idField field:stringM.copy];
        }
    }
    else {
        [self updateObjc:objcs withTable:table idField:idField field:stringM.copy];
    }
}

- (void)updateObjc:(id)objc withTable:(NSString *)table idField:(NSString *)idField field:(NSArray *)fields {
    if(fields.count){
        NSMutableString * say = [NSMutableString stringWithFormat:@"select "];
        for (NSString *field in fields) {
            [say appendString:[NSString stringWithFormat:@"%@,",field]];
        }
        NSRange range;
        range.length = 1;
        range.location = say.length - 1;
        [say deleteCharactersInRange:range];
        [say appendString:[NSString stringWithFormat:@" from %@ where %@='%@'",table,idField,[objc valueForKey:idField]]];
        NSArray <NSDictionary *> * dictArr = [self dictionaryFromSql:say.copy];
        [fields enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [objc setValue:nil forKey:obj];
        }];
        [dictArr enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [objc setValuesForKeysWithDictionary:obj];
        }];
    }
    else {
        NSMutableString * say = [NSMutableString stringWithFormat:@"select * from %@ where %@='%@'",table,idField,[objc valueForKey:idField]];
        NSArray <NSDictionary *> * dictArr = [self dictionaryFromSql:say.copy];
        fields = [self arrayWithPropertyNameForClass:[objc class]];
        [fields enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [objc setValue:nil forKey:obj];
        }];
        [dictArr enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [objc setValuesForKeysWithDictionary:obj];
        }];
    }
}



/**
 将对象转换为字典
 
 @param objc 对象
 */
- (NSDictionary *)dictionaryWithObjc:(id)objc {
    //定义可变字典接收对象属性键值对
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    //属性数量
    unsigned int outCount;
    //得到所有属性列表以及属性数量
    objc_property_t *propertyList = class_copyPropertyList([objc class], &outCount);
    for (NSInteger i  = 0; i < outCount; i++) {
        //遍历属性列表拿到属性名
        NSString * propertyName = [NSString stringWithFormat:@"%s",property_getName(propertyList[i])];
        //取得属性值
        id value = [objc valueForKey:propertyName];
        //给字典赋值
        if(value == NULL){
            value = @"";
        }
        [dict setObject:value forKey:propertyName];
    }
    return dict;
}

/**
 返回所有的属性名
 
 @param cla 类对象
 */
- (NSArray *)arrayWithPropertyNameForClass:(Class)cla {
    NSMutableArray * arrM = [NSMutableArray array];
    unsigned int outCount;
    objc_property_t * properList = class_copyPropertyList(cla, &outCount);
    for (NSInteger i  = 0; i < outCount; i++) {
        NSString * name = [NSString stringWithUTF8String:property_getName(properList[i])];
        [arrM addObject:name];
    }
    return arrM.copy;
}

- (const char *)sqlitePath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"sqlite.db"].UTF8String;
}

@end
