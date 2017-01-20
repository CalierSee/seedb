//
//  SEESqliteManager.h
//  qztourist
//
//  Created by 景彦铭 on 2016/11/20.
//  Copyright © 2016年 景彦铭. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEESqliteManager : NSObject
//指定实例化方法
+ (nonnull instancetype)shareManager;

/**
 将模型存入数据库
 @param datas 单个模型或者模型数组
 @param table 要存入的表的名字
 @return  0失败
 */
- (int)insertDatas:(nonnull id)datas toTable:(nonnull NSString *)table;

/**
 读取指定数据库中的数据并且转换为对应的模型对象
 @param cla 模型类
 @param table 表名
 @param where 条件语句  为空查询全部
 @return 模型数组
 */
- (nullable NSArray *)objectForClass:(nonnull Class)cla fromTable:(nonnull NSString *)table where:(NSString * _Nullable)where completeBlock:(nullable void(^)())complete;

/**
 删除模型对应的数据
 idField为商品id
 @param datas 模型或者模型数组
 @param table 表名
 @param idField 用于判断数据的属性名 使用唯一标识
 @return  0失败
 */
- (int)deleteDatas:(nonnull id)datas forTable:(nonnull NSString *)table forIdField:(nonnull NSString *)idField;

/**
 使用模型或模型数组更新数据库中制定字段的值
 @param datas 模型或者模型数组
 @param table 表名
 @param idField 标识字段  （唯一标识）
 @param field 需要更新的字段
 @return  0失败
 */
- (int)updateDatas:(nonnull id)datas forTable:(nonnull NSString *)table forIdField:(nonnull NSString *)idField field:(nullable NSString *)field,...NS_REQUIRES_NIL_TERMINATION;

/**
 根据表中的字段更新对象模型
 @param objcs 模型或者模型数组
 @param table 表名
 @param idField 标识字段  （唯一标识）
 @param field 更新模型中的属性名  如果为空则更新整个属性
 */
- (void)updateObjcs:(nonnull id)objcs withTable:(nonnull NSString *)table idField:(nonnull NSString *)idField field:(nullable NSString *)field,...NS_REQUIRES_NIL_TERMINATION;
@end
